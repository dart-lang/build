// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';

import 'package:build/build.dart';
import 'package:logging/logging.dart';
import 'package:watcher/watcher.dart';
import 'package:stream_transform/stream_transform.dart';

import '../asset_graph/graph.dart';
import '../asset_graph/node.dart';
import '../package_graph/package_graph.dart';
import '../util/constants.dart';
import 'build_impl.dart';
import 'build_result.dart';
import 'change_watcher.dart';
import 'directory_watcher_factory.dart';
import 'exceptions.dart';
import 'options.dart';
import 'phase.dart';

/// Watches all inputs for changes, and uses a [BuildImpl] to rerun builds as
/// appropriate.
class WatchImpl {
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

  /// A future that completes when the current build is done.
  Future<BuildResult> _currentBuild;
  Future<BuildResult> get currentBuild => _currentBuild;

  /// Whether or not we are currently watching and running builds.
  bool _runningWatch = false;

  /// Whether we are in the process of terminating.
  bool _terminating = false;

  final Completer _onTerminatedCompleter = new Completer();
  Future get onTerminated => _onTerminatedCompleter.future;

  /// Pending expected delete events from the writer.
  final Set<AssetId> _expectedDeletes = new Set<AssetId>();

  WatchImpl(BuildOptions options, List<BuildAction> buildActions)
      : _directoryWatcherFactory = options.directoryWatcherFactory,
        _debounceDelay = options.debounceDelay,
        _packageGraph = options.packageGraph,
        _buildImpl = new BuildImpl(options, buildActions) {
    var existingOnDelete = options.writer.onDelete;
    options.writer.onDelete = (id) {
      _expectedDeletes.add(id);
      if (existingOnDelete != null) existingOnDelete(id);
    };
  }

  final _terminate = new Completer<Null>();

  /// Completes after the current build is done, and stops further builds from
  /// happening.
  Future terminate() async {
    if (_terminating) {
      _logger.warning('Already terminating.');
      return;
    }
    _terminating = true;
    _logger.info('Terminating watchers, no futher builds will be scheduled.');
    _terminate.complete();
    if (_currentBuild != null) {
      _logger.info('Waiting for ongoing build to finish.');
      await _currentBuild;
    }
    _terminating = false;
    _logger.info('Build watching terminated, safe to exit.\n');
    _onTerminatedCompleter.complete();
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

    Future<BuildResult> doBuild(List<List<AssetChange>> changes) {
      _logger.info('Starting next build');
      _expectedDeletes.clear();
      var updates = _collectChanges(changes);
      _currentBuild = _buildImpl.runBuild(updates: updates);
      _currentBuild.then((_) => _currentBuild = null);
      return _currentBuild;
    }

    var changes =
        startFileWatchers(_packageGraph, _logger, _directoryWatcherFactory);
    var buildResults = changes
        .where(_shouldProcess)
        .transform(debounceBuffer(_debounceDelay))
        .transform(startWith([]))
        .transform(takeUntil(_terminate.future))
        .transform(asyncMapBuffer(doBuild))
        .transform(tap(_terminateIfFatal))
        .asBroadcastStream();
    // Make sure there is at least 1 listener
    buildResults.drain();
    return buildResults;
  }

  /// Terminate the watch if the build script updates.
  void _terminateIfFatal(BuildResult result) {
    if (result.status == BuildStatus.failure &&
        result.exception is FatalBuildException) {
      terminate();
    }
  }

  /// Checks if we should skip a watch event for this [change].
  bool _shouldProcess(AssetChange change) {
    if (_isCacheFile(change)) return false;
    if (_isEditOnGeneratedFile(change)) return false;
    if (_isExpectedDelete(change)) return false;
    if (_isUnwatchedDelete(change)) return false;
    return true;
  }

  bool _isCacheFile(AssetChange change) => change.id.path.contains(cacheDir);

  bool _isEditOnGeneratedFile(AssetChange change) =>
      _assetGraph.get(change.id) is GeneratedAssetNode &&
      change.type != ChangeType.REMOVE;

  bool _isExpectedDelete(AssetChange change) =>
      _expectedDeletes.remove(change.id);

  bool _isUnwatchedDelete(AssetChange change) =>
      change.type == ChangeType.REMOVE && !_assetGraph.contains(change.id);
}

Map<AssetId, ChangeType> _collectChanges(List<List<AssetChange>> changes) =>
    new Map.fromIterable(changes.expand((c) => c),
        key: (AssetChange c) => c.id, value: (AssetChange c) => c.type);
