// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';

import 'package:build/build.dart';
import 'package:build_config/build_config.dart';
import 'package:build_runner/src/watcher/asset_change.dart';
import 'package:build_runner/src/watcher/graph_watcher.dart';
import 'package:build_runner/src/watcher/node_watcher.dart';
import 'package:crypto/crypto.dart';
import 'package:glob/glob.dart';
import 'package:logging/logging.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:watcher/watcher.dart';

import '../asset/reader.dart';
import '../asset/writer.dart';
import '../asset_graph/graph.dart';
import '../asset_graph/node.dart';
import '../environment/build_environment.dart';
import '../environment/io_environment.dart';
import '../environment/overridable_environment.dart';
import '../logging/logging.dart';
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
  String configKey,
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
  String outputDir,
  bool trackPerformance,
  bool verbose,
  Map<String, Map<String, dynamic>> builderConfigOverrides,
}) async {
  builderConfigOverrides ??= const {};
  packageGraph ??= new PackageGraph.forThisPackage();
  overrideBuildConfig ??=
      await findBuildConfigOverrides(packageGraph, configKey);
  final targetGraph = await TargetGraph.forPackageGraph(packageGraph,
      overrideBuildConfig: overrideBuildConfig);
  var environment = new OverrideableEnvironment(
      new IOEnvironment(packageGraph, assumeTty),
      reader: reader,
      writer: writer,
      directoryWatcherFactory: directoryWatcherFactory,
      onLog: onLog);
  var options = new BuildOptions(environment,
      configKey: configKey,
      deleteFilesByDefault: deleteFilesByDefault,
      failOnSevere: failOnSevere,
      packageGraph: packageGraph,
      rootPackageConfig: targetGraph.rootPackageConfig,
      logLevel: logLevel,
      debounceDelay: debounceDelay,
      skipBuildScriptCheck: skipBuildScriptCheck,
      enableLowResourcesMode: enableLowResourcesMode,
      outputDir: outputDir,
      trackPerformance: trackPerformance,
      verbose: verbose);
  var terminator = new Terminator(terminateEventStream);

  final buildPhases =
      await createBuildPhases(targetGraph, builders, builderConfigOverrides);

  var watch =
      runWatch(environment, options, buildPhases, terminator.shouldTerminate);

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
WatchImpl runWatch(BuildEnvironment environment, BuildOptions options,
        List<BuildPhase> buildPhases, Future until) =>
    new WatchImpl(environment, options, buildPhases, until,
        options.rootPackageFilesWhitelist.map((g) => new Glob(g)));

typedef Future<BuildResult> _BuildAction(List<List<AssetChange>> changes);

class WatchImpl implements BuildState {
  AssetGraph _assetGraph;
  AssetGraph get assetGraph => _assetGraph;

  BuildDefinition _buildDefinition;
  final String _configKey; // may be null
  final Iterable<Glob> _rootPackageFilesWhitelist;

  /// Delay to wait for more file watcher events.
  final Duration _debounceDelay;

  /// Injectable factory for creating directory watchers.
  final DirectoryWatcherFactory _directoryWatcherFactory;

  /// Should complete when we need to kill the build.
  final _terminateCompleter = new Completer<Null>();

  /// The [PackageGraph] for the current program.
  final PackageGraph packageGraph;

  @override
  Future<BuildResult> currentBuild;

  /// Pending expected delete events from the build.
  final Set<AssetId> _expectedDeletes = new Set<AssetId>();

  final _readerCompleter = new Completer<AssetReader>();
  Future<AssetReader> get reader => _readerCompleter.future;

  WatchImpl(
      BuildEnvironment environment,
      BuildOptions options,
      List<BuildPhase> buildPhases,
      Future until,
      this._rootPackageFilesWhitelist)
      : _configKey = options.configKey,
        _directoryWatcherFactory = environment.directoryWatcherFactory,
        _debounceDelay = options.debounceDelay,
        packageGraph = options.packageGraph {
    buildResults =
        _run(environment, options, buildPhases, until).asBroadcastStream();
  }

  @override
  Stream<BuildResult> buildResults;

  /// Runs a build any time relevant files change.
  ///
  /// Only one build will run at a time, and changes are batched.
  ///
  /// File watchers are scheduled synchronously.
  Stream<BuildResult> _run(BuildEnvironment environment, BuildOptions options,
      List<BuildPhase> buildPhases, Future until) {
    var firstBuildCompleter = new Completer<BuildResult>();
    currentBuild = firstBuildCompleter.future;
    var controller = new StreamController<BuildResult>();

    // We need this inside `doBuild`, but we won't actually create it until
    // the end of this function. It must be non-null before `doBuild` is
    // invoked.
    BuildImpl build;

    Future<BuildResult> doBuild(List<List<AssetChange>> changes) async {
      assert(build != null);
      _logger.info('\nStarting Build');
      var mergedChanges = _collectChanges(changes);

      _expectedDeletes.clear();
      if (!options.skipBuildScriptCheck) {
        if (_buildDefinition.buildScriptUpdates
            .hasBeenUpdated(mergedChanges.keys.toSet())) {
          _terminateCompleter.complete();
          _logger.severe('Terminating builds due to build script update');
          return new BuildResult(BuildStatus.failure, []);
        }
      }
      return build.run(mergedChanges);
    }

    var terminate = Future.any([until, _terminateCompleter.future]).then((_) {
      _logger.info('Terminating. No further builds will be scheduled\n');
    });

    Digest originalRootPackagesDigest;
    final rootPackagesId = new AssetId(packageGraph.root.name, '.packages');

    // Start watching files immediately, before the first build is even started.
    var graphWatcher = new PackageGraphWatcher(packageGraph,
        logger: _logger,
        watch: (node) =>
            new PackageNodeWatcher(node, watch: _directoryWatcherFactory));
    graphWatcher
        .watch()
        .asyncMap<AssetChange>((change) {
          // Delay any events until the first build is completed.
          if (firstBuildCompleter.isCompleted) return change;
          return firstBuildCompleter.future.then((_) => change);
        })
        .asyncMap<AssetChange>((change) {
          var id = change.id;
          assert(originalRootPackagesDigest != null);
          if (id == rootPackagesId) {
            // Kill future builds if the root packages file changes.
            return environment.reader.readAsBytes(rootPackagesId).then((bytes) {
              if (md5.convert(bytes) != originalRootPackagesDigest) {
                _terminateCompleter.complete();
                _logger
                    .severe('Terminating builds due to package graph update, '
                        'please restart the build.');
              }
              return change;
            });
          } else if (_isBuildYaml(id) ||
              _isConfiguredBuildYaml(id) ||
              _isPackageBuildYamlOverride(id)) {
            // Kill future builds if the build.yaml files change.
            _terminateCompleter.complete();
            _logger.severe(
                'Terminating builds due to ${id.package}:${id.path} update.');
          }
          return change;
        })
        .where(_shouldProcess)
        .transform(debounceBuffer(_debounceDelay))
        .transform(takeUntil(terminate))
        .transform(asyncMapBuffer(_recordCurrentBuild(doBuild)))
        .listen((BuildResult result) {
          if (controller.isClosed) return;
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
      await logTimedAsync(_logger, 'Waiting for all file watchers to be ready',
          () => graphWatcher.ready);
      originalRootPackagesDigest =
          md5.convert(await environment.reader.readAsBytes(rootPackagesId));
      _buildDefinition = await BuildDefinition.prepareWorkspace(
          environment, options, buildPhases,
          onDelete: _expectedDeletes.add);
      _readerCompleter.complete(new SingleStepReader(
          _buildDefinition.reader,
          _buildDefinition.assetGraph,
          buildPhases.length,
          true,
          packageGraph.root.name,
          null));
      _assetGraph = _buildDefinition.assetGraph;
      build = await BuildImpl.create(_buildDefinition, options, buildPhases,
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

  bool _isBuildYaml(AssetId id) => id.path == 'build.yaml';
  bool _isConfiguredBuildYaml(AssetId id) =>
      id.package == packageGraph.root.name &&
      id.path == 'build.$_configKey.yaml';
  bool _isPackageBuildYamlOverride(AssetId id) =>
      id.package == packageGraph.root.name &&
      id.path.contains(_packageBuildYamlRegexp);
  final _packageBuildYamlRegexp = new RegExp(r'^[a-z0-9_]+\.build\.yaml$');

  /// Checks if we should skip a watch event for this [change].
  bool _shouldProcess(AssetChange change) {
    assert(_assetGraph != null);
    if (_isCacheFile(change) && !_assetGraph.contains(change.id)) return false;
    var node = _assetGraph.get(change.id);
    if (node != null) {
      if (!node.isInteresting) return false;
      if (_isAddOrEditOnGeneratedFile(node, change.type)) return false;
    } else {
      if (change.type == ChangeType.REMOVE) return false;
      if (!_isWhitelistedPath(change.id)) return false;
    }
    if (_isExpectedDelete(change)) return false;
    return true;
  }

  bool _isCacheFile(AssetChange change) => change.id.path.startsWith(cacheDir);

  bool _isAddOrEditOnGeneratedFile(AssetNode node, ChangeType changeType) =>
      node.isGenerated && changeType != ChangeType.REMOVE;

  bool _isExpectedDelete(AssetChange change) =>
      _expectedDeletes.remove(change.id);

  bool _isWhitelistedPath(AssetId id) {
    if (packageGraph[id.package].isRoot) {
      return _rootPackageFilesWhitelist.any((glob) => glob.matches(id.path));
    } else {
      return id.path.startsWith('lib/');
    }
  }
}

Map<AssetId, ChangeType> _collectChanges(List<List<AssetChange>> changes) {
  var changeMap = <AssetId, ChangeType>{};
  for (AssetChange change in changes.expand((l) => l)) {
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
