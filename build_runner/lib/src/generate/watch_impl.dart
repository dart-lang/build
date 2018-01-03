// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';

import 'package:build/build.dart';
import 'package:build_config/build_config.dart';
import 'package:build_runner/src/watcher/asset_change.dart';
import 'package:build_runner/src/watcher/graph_watcher.dart';
import 'package:build_runner/src/watcher/node_watcher.dart';
import 'package:logging/logging.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:watcher/watcher.dart';

import '../asset/reader.dart';
import '../asset/writer.dart';
import '../asset_graph/graph.dart';
import '../asset_graph/node.dart';
import '../package_graph/apply_builders.dart';
import '../package_graph/build_config_overrides.dart';
import '../package_graph/package_graph.dart';
import '../package_graph/target_graph.dart';
import '../server/server.dart';
import '../util/constants.dart';
import 'build_definition.dart';
import 'build_impl.dart';
import 'build_result.dart';
import 'directory_watcher_factory.dart';
import 'options.dart';
import 'phase.dart';
import 'terminator.dart';

final _logger = new Logger('Watch');

Future<ServeHandler> watch(
  List<BuilderApplication> builders, {
  bool deleteFilesByDefault,
  bool failOnSevere,
  bool assumeTty,
  PackageGraph packageGraph,
  RunnerAssetReader reader,
  RunnerAssetWriter writer,
  Level logLevel,
  onLog(LogRecord record),
  Duration debounceDelay,
  DirectoryWatcherFactory directoryWatcherFactory,
  Stream terminateEventStream,
  bool skipBuildScriptCheck,
  bool enableLowResourcesMode,
  Map<String, BuildConfig> overrideBuildConfig,
}) async {
  var options = new BuildOptions(
      assumeTty: assumeTty,
      deleteFilesByDefault: deleteFilesByDefault,
      failOnSevere: failOnSevere,
      packageGraph: packageGraph,
      reader: reader,
      writer: writer,
      logLevel: logLevel,
      onLog: onLog,
      debounceDelay: debounceDelay,
      directoryWatcherFactory: directoryWatcherFactory,
      skipBuildScriptCheck: skipBuildScriptCheck,
      enableLowResourcesMode: enableLowResourcesMode);
  var terminator = new Terminator(terminateEventStream);

  overrideBuildConfig ??= await findBuildConfigOverrides(options.packageGraph);
  final targetGraph = await TargetGraph.forPackageGraph(options.packageGraph);
  final buildActions = await createBuildActions(targetGraph, builders,
      overrideBuildConfig: overrideBuildConfig);

  var watch = runWatch(options, buildActions, terminator.shouldTerminate,
      targetGraph.rootPackageConfig);

  // ignore: unawaited_futures
  watch.buildResults.drain().then((_) async {
    await terminator.cancel();
    await options.logListener.cancel();
  });

  return createServeHandler(watch);
}

/// Repeatedly run builds as files change on disk until [until] fires.
///
/// Sets up file watchers and collects changes then triggers new builds. When
/// [until] fires the file watchers will be stopped and up to one additional
/// build may run if there were pending changes.
///
/// The [BuildState.buildResults] stream will end after the final build has been
/// run.
WatchImpl runWatch(BuildOptions options, List<BuildAction> buildActions,
        Future until, BuildConfig rootPackageConfig) =>
    new WatchImpl(options, buildActions, until, rootPackageConfig);

typedef Future<BuildResult> _BuildAction(List<List<AssetChange>> changes);

class WatchImpl implements BuildState {
  AssetGraph _assetGraph;
  BuildDefinition _buildDefinition;
  final BuildConfig _rootPackageConfig;

  /// Delay to wait for more file watcher events.
  final Duration _debounceDelay;

  /// Injectable factory for creating directory watchers.
  final DirectoryWatcherFactory _directoryWatcherFactory;

  /// The [PackageGraph] for the current program.
  final PackageGraph packageGraph;

  @override
  Future<BuildResult> currentBuild;

  /// Pending expected delete events from the build.
  final Set<AssetId> _expectedDeletes = new Set<AssetId>();

  final _readerCompleter = new Completer<DigestAssetReader>();
  Future<DigestAssetReader> get reader => _readerCompleter.future;

  WatchImpl(BuildOptions options, List<BuildAction> buildActions, Future until,
      this._rootPackageConfig)
      : _directoryWatcherFactory = options.directoryWatcherFactory,
        _debounceDelay = options.debounceDelay,
        packageGraph = options.packageGraph {
    buildResults = _run(options, buildActions, until).asBroadcastStream();
  }

  @override
  Stream<BuildResult> buildResults;

  /// Runs a build any time relevant files change.
  ///
  /// Only one build will run at a time, and changes are batched.
  ///
  /// File watchers are scheduled synchronously.
  Stream<BuildResult> _run(
      BuildOptions options, List<BuildAction> buildActions, Future until) {
    var fatalBuildCompleter = new Completer();
    var firstBuildCompleter = new Completer<BuildResult>();
    currentBuild = firstBuildCompleter.future;
    var controller = new StreamController<BuildResult>();

    // We need this inside `doBuild`, but we won't actually create it until
    // the end of this function. It must be non-null before `doBuild` is
    // invoked.
    BuildImpl build;

    Future<BuildResult> doBuild(List<List<AssetChange>> changes) async {
      assert(build != null);
      var mergedChanges = _collectChanges(changes);

      _expectedDeletes.clear();
      if (!options.skipBuildScriptCheck) {
        if (_buildDefinition.buildScriptUpdates
            .hasBeenUpdated(mergedChanges.keys.toSet())) {
          fatalBuildCompleter.complete();
          _logger.severe('Terminating builds due to build script update');
          return new BuildResult(BuildStatus.failure, []);
        }
      }
      return build.run(mergedChanges);
    }

    var terminate = Future.any([until, fatalBuildCompleter.future]).then((_) {
      _logger.info('Terminating. No further builds will be scheduled\n');
    });

    // Start watching files immediately, before the first build is even started.
    new PackageGraphWatcher(packageGraph,
            logger: _logger,
            watch: (node) =>
                new PackageNodeWatcher(node, watch: _directoryWatcherFactory))
        .watch()
        .asyncMap<AssetChange>((change) {
          // Delay any events until the first build is completed.
          if (firstBuildCompleter.isCompleted) return change;
          return firstBuildCompleter.future.then((_) => change);
        })
        .where(_shouldProcess)
        .transform(debounceBuffer(_debounceDelay))
        .transform(takeUntil(terminate))
        .transform(asyncMapBuffer(_recordCurrentBuild(doBuild)))
        .listen((BuildResult result) {
          if (controller.isClosed) return;
          if (result.status != BuildStatus.failure &&
              options.failOnSevere &&
              options.severeLogHandled) {
            options.severeLogHandled = false;
            result = new BuildResult(
              BuildStatus.failure,
              result.outputs,
              exception: 'A severe log was handled. See log for details',
              performance: result.performance,
            );
          }
          controller.add(result);
        })
        .onDone(() async {
          await currentBuild;
          await _buildDefinition.resourceManager.beforeExit();
          await controller.close();
          _logger.info('Builds finished. Safe to exit\n');
        });

    // Schedule the actual first build for the future so we can return the
    // stream synchronously.
    () async {
      _buildDefinition = await BuildDefinition.prepareWorkspace(
          options, buildActions, _rootPackageConfig,
          onDelete: _expectedDeletes.add);
      _readerCompleter.complete(new SingleStepReader(
          _buildDefinition.reader,
          _buildDefinition.assetGraph,
          buildActions.length,
          packageGraph.root.name,
          null));
      _assetGraph = _buildDefinition.assetGraph;
      build = await BuildImpl.create(_buildDefinition, buildActions,
          onDelete: _expectedDeletes.add);

      // It is possible this is already closed if the user kills the process
      // early, which results in an exception without this check.
      if (!controller.isClosed) controller.add(build.firstBuild);

      firstBuildCompleter.complete(build.firstBuild);
    }();

    return controller.stream;
  }

  _BuildAction _recordCurrentBuild(_BuildAction build) => (changes) =>
      currentBuild = build(changes)..then((_) => currentBuild = null);

  /// Checks if we should skip a watch event for this [change].
  bool _shouldProcess(AssetChange change) {
    assert(_assetGraph != null);
    if (_isCacheFile(change) && !_assetGraph.contains(change.id)) return false;
    var node = _assetGraph.get(change.id);
    if (node != null) {
      if (!node.isInteresting) return false;
      if (_isEditOnGeneratedFile(node, change.type)) return false;
    } else {
      if (change.type == ChangeType.REMOVE) return false;
      if (!_isWhitelistedPath(change.id)) return false;
    }
    if (_isExpectedDelete(change)) return false;
    return true;
  }

  bool _isCacheFile(AssetChange change) => change.id.path.startsWith(cacheDir);

  bool _isEditOnGeneratedFile(AssetNode node, ChangeType changeType) =>
      node.isGenerated && changeType != ChangeType.REMOVE;

  bool _isExpectedDelete(AssetChange change) =>
      _expectedDeletes.remove(change.id);

  bool _isWhitelistedPath(AssetId id) {
    if (packageGraph[id.package].isRoot) {
      return rootPackageGlobsWhitelist.any((glob) => glob.matches(id.path));
    } else {
      return id.path.startsWith('lib/');
    }
  }
}

Map<AssetId, ChangeType> _collectChanges(List<List<AssetChange>> changes) {
  var changeMap = <AssetId, ChangeType>{};
  for (var change in changes.expand((l) => l)) {
    var originalChangeType = changeMap[change.id];
    if (originalChangeType != null) {
      switch (originalChangeType) {
        case ChangeType.ADD:
          if (change.type == ChangeType.REMOVE) {
            // ADD followed by REMOVE, just remove the change.
            changeMap.remove(change.id);
          }
          break;
        case ChangeType.REMOVE:
          if (change.type == ChangeType.ADD) {
            // REMOVE followed by ADD, convert to a MODIFY
            changeMap[change.id] = ChangeType.MODIFY;
          } else if (change.type == ChangeType.MODIFY) {
            // REMOVE followed by MODIFY isn't sensible, just throw.
            throw new StateError(
                'Internal error, got REMOVE event followed by MODIFY event for '
                '${change.id}.');
          }
          break;
        case ChangeType.MODIFY:
          if (change.type == ChangeType.REMOVE) {
            // MODIFY followed by REMOVE, convert to REMOVE
            changeMap[change.id] = change.type;
          } else if (change.type == ChangeType.ADD) {
            // MODIFY followed by ADD isn't sensible, just throw.
            throw new StateError(
                'Internal error, got MODIFY event followed by ADD event for '
                '${change.id}.');
          }
          break;
      }
    } else {
      changeMap[change.id] = change.type;
    }
  }
  return changeMap;
}
