// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:watcher/watcher.dart';

import '../asset/cache.dart';
import '../asset/id.dart';
import '../asset/reader.dart';
import '../asset/writer.dart';
import '../asset_graph/graph.dart';
import '../asset_graph/node.dart';
import '../package_graph/package_graph.dart';
import 'build_impl.dart';
import 'build_result.dart';
import 'directory_watcher_factory.dart';
import 'phase.dart';

/// Watches all inputs for changes, and uses a [BuildImpl] to rerun builds as
/// appropriate.
class WatchImpl {
  /// All file listeners currently set up.
  final _allListeners = <StreamSubscription>[];

  /// The [AssetCache] being used for builds.
  final AssetCache _assetCache;

  /// The [AssetGraph] being shared with [_buildImpl]
  AssetGraph get _assetGraph => _buildImpl.assetGraph;

  /// The [BuildImpl] being used to run builds.
  final BuildImpl _buildImpl;

  /// Delay to wait for more file watcher events.
  final Duration _debounceDelay;

  /// Injectable factory for creating directory watchers.
  final DirectoryWatcherFactory _directoryWatcherFactory;

  /// A logger to use!
  final _logger = new Logger('Watch');

  /// The [PackageGraph] for the current program.
  final PackageGraph _packageGraph;

  /// Shared [AssetWriter] with [_buildImpl]
  final AssetWriter _writer;

  /// A future that completes when the current build is done.
  Future _currentBuild;

  /// Whether or not another build is scheduled.
  bool _nextBuildScheduled;

  /// Controller for the results stream.
  StreamController<BuildResult> _resultStreamController;

  /// Whether or not we are currently watching and running builds.
  bool _runningWatch = false;

  /// Whether we are in the process of terminating.
  bool _terminating = false;

  WatchImpl(
      this._directoryWatcherFactory,
      this._debounceDelay,
      this._assetCache,
      AssetReader reader,
      AssetWriter writer,
      PackageGraph packageGraph,
      List<List<Phase>> phaseGroups)
      : _packageGraph = packageGraph,
        _writer = writer,
        _buildImpl = new BuildImpl(reader, writer, packageGraph, phaseGroups);

  /// Completes after the current build is done, and stops further builds from
  /// happening.
  Future terminate() async {
    if (_terminating) throw new StateError('Already terminating.');
    if (_resultStreamController == null) {
      throw new StateError('`terminate` called before `runWatch`');
    }

    _terminating = true;
    _logger.info('Terminating watchers, no futher builds will be scheduled.');
    _nextBuildScheduled = false;
    for (var listener in _allListeners) {
      await listener.cancel();
    }
    _allListeners.clear();
    if (_currentBuild != null) {
      _logger.info('Waiting for ongoing build to finish.');
      await _currentBuild;
    }
    await _resultStreamController.close();
    _terminating = false;
    _logger.info('Build watching terminated.');
  }

  /// Runs a build any time relevant files change.
  ///
  /// Only one build will run at a time, and changes are batched.
  Stream<BuildResult> runWatch() {
    if (_runningWatch) {
      throw new StateError(
          '`runWatch` called twice, `terminate` must be called in between.');
    }

    _runningWatch = true;
    _resultStreamController = new StreamController<BuildResult>();
    _nextBuildScheduled = false;
    var updatedInputs = new Map<AssetId, ChangeType>();

    doBuild([bool force = false]) {
      // Don't schedule more builds if we are turning down.
      if (_terminating) return;

      if (_currentBuild != null) {
        if (_nextBuildScheduled == false) {
          _logger.info('Scheduling next build');
          _nextBuildScheduled = true;
        }
        return;
      }
      assert(_nextBuildScheduled == false);

      /// Copy [updatedInputs] so that it doesn't get modified after this point.
      /// Any further updates will be scheduled for the next build.
      ///
      /// Only copy the "interesting" outputs.
      var updatedInputsCopy = <AssetId, ChangeType>{};
      updatedInputs.forEach((input, changeType) {
        if (_shouldSkipInput(input)) return;
        updatedInputsCopy[input] = changeType;
      });
      updatedInputs.clear();
      if (updatedInputsCopy.isEmpty && !force) {
        return;
      }

      _logger.info('Preparing for next build');
      Future clearNodeAndDeps(
          AssetId id, AssetId primaryInput, ChangeType rootChangeType) async {
        var node = _assetGraph.get(id);
        if (node == null) return;
        _assetCache.remove(id);

        /// Update all ouputs of this asset as well.
        await Future.wait(node.outputs.map((output) =>
            clearNodeAndDeps(output, primaryInput, rootChangeType)));

        /// For deletes, prune the graph.
        if (id == primaryInput && rootChangeType == ChangeType.REMOVE) {
          _assetGraph.remove(id);
        }
        if (node is GeneratedAssetNode) {
          node.needsUpdate = true;
          if (rootChangeType == ChangeType.REMOVE &&
              node.primaryInput == primaryInput) {
            _assetGraph.remove(id);
            await _writer.delete(id);
          }
        }
      }

      Future
          .wait(updatedInputsCopy.keys.map((input) =>
              clearNodeAndDeps(input, input, updatedInputsCopy[input])))
          .then((_) {
        _logger.info('Starting build');
        _currentBuild = _buildImpl.runBuild();
        _currentBuild.then((result) {
          if (result.status == BuildStatus.Success) {
            _logger.info('Build completed successfully');
          } else {
            _logger.warning('Build failed');
          }
          _resultStreamController.add(result);
          _currentBuild = null;
          if (_nextBuildScheduled) {
            _nextBuildScheduled = false;
            doBuild();
          }
        });
      });
    }

    Timer buildTimer;
    scheduleBuild() {
      if (buildTimer?.isActive == true) buildTimer.cancel();
      buildTimer = new Timer(_debounceDelay, doBuild);
    }

    final watchers = <DirectoryWatcher>[];
    _logger.info('Setting up file watchers');
    for (var package in _packageGraph.allPackages.values) {
      _logger.fine('Setting up watcher at ${package.location.toFilePath()}');
      var watcher = _directoryWatcherFactory(package.location.toFilePath());
      watchers.add(watcher);
      _allListeners.add(watcher.events.listen((WatchEvent e) {
        _logger.fine('Got WatchEvent for path ${e.path}');
        var id = new AssetId(package.name, path.normalize(e.path));
        var node = _assetGraph.get(id);
        // Short circuit for deletes of nodes that aren't in the graph.
        if (e.type == ChangeType.REMOVE && node == null) return;

        updatedInputs[id] = e.type;
        scheduleBuild();
      }));
    }

    Future.wait(watchers.map((w) => w.ready)).then((_) {
      // Schedule the first build!
      doBuild(true);
    });

    return _resultStreamController.stream;
  }

  /// Checks if we should skip a watch event for this [id].
  bool _shouldSkipInput(AssetId id) {
    if (id.path.startsWith('.build')) return true;
    var node = _assetGraph.get(id);
    return node is GeneratedAssetNode;
  }
}
