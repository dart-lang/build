// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:watcher/watcher.dart';

import '../asset/id.dart';
import '../asset/writer.dart';
import '../asset_graph/graph.dart';
import '../asset_graph/node.dart';
import '../logging/logging.dart';
import '../package_graph/package_graph.dart';
import '../util/constants.dart';
import 'build_impl.dart';
import 'build_result.dart';
import 'directory_watcher_factory.dart';
import 'exceptions.dart';
import 'options.dart';
import 'phase.dart';

/// Watches all inputs for changes, and uses a [BuildImpl] to rerun builds as
/// appropriate.
class WatchImpl {
  /// All file listeners currently set up.
  final _allListeners = <StreamSubscription>[];

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
  Future<BuildResult> _currentBuild;
  Future<BuildResult> get currentBuild => _currentBuild;

  /// Whether or not another build is scheduled.
  bool _nextBuildScheduled;

  /// Controller for the results stream.
  StreamController<BuildResult> _resultStreamController;

  /// Whether or not we are currently watching and running builds.
  bool _runningWatch = false;

  /// Whether we are in the process of terminating.
  bool _terminating = false;

  Completer _onTerminatedCompleter = new Completer();
  Future get onTerminated => _onTerminatedCompleter.future;

  WatchImpl(BuildOptions options, PhaseGroup phaseGroup)
      : _directoryWatcherFactory = options.directoryWatcherFactory,
        _debounceDelay = options.debounceDelay,
        _writer = options.writer,
        _packageGraph = options.packageGraph,
        _buildImpl = new BuildImpl(options, phaseGroup);

  /// Completes after the current build is done, and stops further builds from
  /// happening.
  Future terminate() async {
    if (_terminating) {
      _logger.warning('Already terminating.');
      return;
    }
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
    if (_resultStreamController.hasListener) {
      _logger.info('Closing build result stream.');
      await _resultStreamController.close();
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
    _resultStreamController = new StreamController<BuildResult>();
    _nextBuildScheduled = false;
    var updatedInputs = new Map<AssetId, ChangeType>();

    void doBuild([bool force = false]) {
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

      /// Any updates after this point should cause updates to the [AssetGraph]
      /// for later builds.
      var validAsOf = new DateTime.now();

      /// Copy [updatedInputs] so that it doesn't get modified after this point.
      /// Any further updates will be scheduled for the next build.
      ///
      /// Only copy the "interesting" outputs.
      var updatedInputsCopy = <AssetId, ChangeType>{};
      updatedInputs.forEach((input, changeType) {
        if (_shouldSkipInput(input, changeType)) return;
        updatedInputsCopy[input] = changeType;
      });
      updatedInputs.clear();
      if (updatedInputsCopy.isEmpty && !force) {
        return;
      }

      _logger.info('Starting next build');
      _currentBuild =
          _buildImpl.runBuild(validAsOf: validAsOf, updates: updatedInputsCopy);
      _currentBuild.then((result) {
        // Terminate the watcher if the build script is updated, there is no
        // need to continue listening.
        if (result.status == BuildStatus.failure &&
            result.exception is FatalBuildException) {
          terminate();
        }

        if (_resultStreamController.hasListener) {
          _resultStreamController.add(result);
        }
        _currentBuild = null;
        if (_nextBuildScheduled) {
          _nextBuildScheduled = false;
          doBuild();
        }
      });
    }

    Timer buildTimer;
    void scheduleBuild() {
      if (buildTimer?.isActive == true) buildTimer.cancel();
      buildTimer = new Timer(_debounceDelay, doBuild);
    }

    logWithTime(_logger, 'Setting up file watchers', () {
      final watchers = <DirectoryWatcher>[];

      // Collect absolute file paths for all the packages. This needs to happen
      // before setting up the watchers.
      final absolutePackagePaths = <PackageNode, String>{};
      for (var package in _packageGraph.allPackages.values) {
        absolutePackagePaths[package] =
            path.normalize(path.absolute(package.location.toFilePath()));
      }

      // Set up watchers for all the packages
      for (var package in _packageGraph.allPackages.values) {
        var absolutePackagePath = absolutePackagePaths[package];
        _logger.fine('Setting up watcher at $absolutePackagePath');

        // Ignore all subfolders which are other packages.
        var pathsToIgnore = absolutePackagePaths.values
            .where((path) =>
                path != absolutePackagePath &&
                path.startsWith(absolutePackagePath))
            .toList();

        var watcher = _directoryWatcherFactory(absolutePackagePath);
        watchers.add(watcher);
        _allListeners.add(watcher.events.listen((WatchEvent e) {
          var changePath = _normalizeChangePath(e.path, absolutePackagePaths);
          if (changePath == null) return;

          // Check for ignored paths and immediately bail.
          if (pathsToIgnore.any((path) => changePath.startsWith(path))) return;

          var relativePath =
              path.relative(changePath, from: absolutePackagePath);
          _logger.finest(
              'Got ${e.type} event for path $relativePath from ${watcher.path}');
          var id = new AssetId(package.name, relativePath);
          var node = _assetGraph.get(id);
          // Short circuit for deletes of nodes that aren't in the graph.
          if (e.type == ChangeType.REMOVE && node == null) return;

          updatedInputs[id] = e.type;
          scheduleBuild();
        }));
      }

      return Future.wait(watchers.map((w) => w.ready));
    }).then((_) {
      // Schedule the first build!
      doBuild(true);
    });

    return _resultStreamController.stream;
  }

  /// Checks if we should skip a watch event for this [id].
  bool _shouldSkipInput(AssetId id, ChangeType type) {
    if (id.path.contains(cacheDir)) return true;
    var node = _assetGraph.get(id);
    return node is GeneratedAssetNode && type != ChangeType.REMOVE;
  }

  // Convert `packages` paths to absolute paths. Returns null if it finds an
  // invalid package path.
  String _normalizeChangePath(
      String changePath, Map<PackageNode, String> absolutePackagePaths) {
    var changePathParts = path.split(changePath);
    var packagesIndex = changePathParts.indexOf('packages');
    if (packagesIndex == -1) return changePath;

    if (changePathParts.length < packagesIndex + 2) {
      _logger.severe('Invalid change path: $changePath');
      return null;
    }

    var packageName = changePathParts[packagesIndex + 1];
    var packageNode = _packageGraph[packageName];
    if (packageNode == null) {
      _logger.severe('Got update for invalid package: $packageName');
      return null;
    }
    var packagePath = absolutePackagePaths[packageNode];
    var libPath = path.joinAll(['lib']
      ..addAll(
          changePathParts.getRange(packagesIndex + 2, changePathParts.length)));
    return path.join(packagePath, libPath);
  }
}
