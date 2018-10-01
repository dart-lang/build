// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';
import 'package:build_config/build_config.dart';
import 'package:build_runner/src/package_graph/build_config_overrides.dart';
import 'package:build_runner/src/watcher/asset_change.dart';
import 'package:build_runner/src/watcher/graph_watcher.dart';
import 'package:build_runner/src/watcher/node_watcher.dart';
import 'package:build_runner_core/build_runner_core.dart';
import 'package:build_runner_core/src/asset_graph/graph.dart';
import 'package:build_runner_core/src/asset_graph/node.dart';
import 'package:build_runner_core/src/generate/build_impl.dart';
import 'package:build_runner_core/src/package_graph/target_graph.dart';
import 'package:crypto/crypto.dart';
import 'package:logging/logging.dart';
import 'package:pedantic/pedantic.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:watcher/watcher.dart';

import '../logging/std_io_logging.dart';
import '../server/server.dart';
import 'terminator.dart';

final _logger = Logger('Watch');

Future<ServeHandler> watch(
  List<BuilderApplication> builders, {
  bool deleteFilesByDefault,
  bool assumeTty,
  String configKey,
  PackageGraph packageGraph,
  RunnerAssetReader reader,
  RunnerAssetWriter writer,
  Resolvers resolvers,
  Level logLevel,
  onLog(LogRecord record),
  Duration debounceDelay,
  DirectoryWatcher Function(String) directoryWatcherFactory,
  Stream terminateEventStream,
  bool skipBuildScriptCheck,
  bool enableLowResourcesMode,
  Map<String, BuildConfig> overrideBuildConfig,
  Map<String, String> outputMap,
  bool outputSymlinksOnly,
  bool trackPerformance,
  bool verbose,
  Map<String, Map<String, dynamic>> builderConfigOverrides,
  bool isReleaseBuild,
  List<String> buildDirs,
  String logPerformanceDir,
}) async {
  builderConfigOverrides ??= const {};
  packageGraph ??= PackageGraph.forThisPackage();

  var environment = OverrideableEnvironment(
      IOEnvironment(packageGraph,
          assumeTty: assumeTty,
          outputMap: outputMap,
          outputSymlinksOnly: outputSymlinksOnly),
      reader: reader,
      writer: writer,
      onLog: onLog ?? stdIOLogListener(assumeTty: assumeTty, verbose: verbose));
  var logSubscription =
      LogSubscription(environment, verbose: verbose, logLevel: logLevel);
  overrideBuildConfig ??=
      await findBuildConfigOverrides(packageGraph, configKey);
  var options = await BuildOptions.create(
    logSubscription,
    deleteFilesByDefault: deleteFilesByDefault,
    packageGraph: packageGraph,
    overrideBuildConfig: overrideBuildConfig,
    debounceDelay: debounceDelay,
    skipBuildScriptCheck: skipBuildScriptCheck,
    enableLowResourcesMode: enableLowResourcesMode,
    trackPerformance: trackPerformance,
    buildDirs: buildDirs,
    logPerformanceDir: logPerformanceDir,
    resolvers: resolvers,
  );
  var terminator = Terminator(terminateEventStream);

  var watch = _runWatch(
      options,
      environment,
      builders,
      builderConfigOverrides,
      terminator.shouldTerminate,
      directoryWatcherFactory,
      configKey,
      outputMap?.isNotEmpty == true,
      isReleaseMode: isReleaseBuild ?? false);

  unawaited(watch.buildResults.drain().then((_) async {
    await terminator.cancel();
    await options.logListener.cancel();
  }));

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
WatchImpl _runWatch(
        BuildOptions options,
        BuildEnvironment environment,
        List<BuilderApplication> builders,
        Map<String, Map<String, dynamic>> builderConfigOverrides,
        Future until,
        DirectoryWatcher Function(String) directoryWatcherFactory,
        String configKey,
        bool willCreateOutputDirs,
        {bool isReleaseMode = false}) =>
    WatchImpl(options, environment, builders, builderConfigOverrides, until,
        directoryWatcherFactory, configKey, willCreateOutputDirs,
        isReleaseMode: isReleaseMode);

typedef Future<BuildResult> _BuildAction(List<List<AssetChange>> changes);

class _OnDeleteWriter implements RunnerAssetWriter {
  RunnerAssetWriter _writer;
  Function(AssetId id) _onDelete;

  _OnDeleteWriter(this._writer, this._onDelete);

  @override
  Future delete(AssetId id) {
    _onDelete(id);
    return _writer.delete(id);
  }

  @override
  Future writeAsBytes(AssetId id, List<int> bytes) =>
      _writer.writeAsBytes(id, bytes);

  @override
  Future writeAsString(AssetId id, String contents,
          {Encoding encoding = utf8}) =>
      _writer.writeAsString(id, contents, encoding: encoding);
}

class WatchImpl implements BuildState {
  BuildImpl _build;

  AssetGraph get assetGraph => _build?.assetGraph;

  final _readyCompleter = Completer<Null>();
  Future<Null> get ready => _readyCompleter.future;

  final String _configKey; // may be null

  /// Delay to wait for more file watcher events.
  final Duration _debounceDelay;

  /// Injectable factory for creating directory watchers.
  final DirectoryWatcher Function(String) _directoryWatcherFactory;

  /// Whether or not we will be creating any output directories.
  ///
  /// If not, then we don't care about source edits that don't have outputs.
  final bool _willCreateOutputDirs;

  /// Should complete when we need to kill the build.
  final _terminateCompleter = Completer<Null>();

  /// The [PackageGraph] for the current program.
  final PackageGraph packageGraph;

  /// The [TargetGraph] for the current program.
  final TargetGraph _targetGraph;

  @override
  Future<BuildResult> currentBuild;

  /// Pending expected delete events from the build.
  final Set<AssetId> _expectedDeletes = Set<AssetId>();

  FinalizedReader _reader;
  FinalizedReader get reader => _reader;

  WatchImpl(
      BuildOptions options,
      BuildEnvironment environment,
      List<BuilderApplication> builders,
      Map<String, Map<String, dynamic>> builderConfigOverrides,
      Future until,
      this._directoryWatcherFactory,
      this._configKey,
      this._willCreateOutputDirs,
      {bool isReleaseMode = false})
      : _debounceDelay = options.debounceDelay,
        packageGraph = options.packageGraph,
        _targetGraph = options.targetGraph {
    buildResults = _run(
            options, environment, builders, builderConfigOverrides, until,
            isReleaseMode: isReleaseMode)
        .asBroadcastStream();
  }

  @override
  Stream<BuildResult> buildResults;

  /// Runs a build any time relevant files change.
  ///
  /// Only one build will run at a time, and changes are batched.
  ///
  /// File watchers are scheduled synchronously.
  Stream<BuildResult> _run(
      BuildOptions options,
      BuildEnvironment environment,
      List<BuilderApplication> builders,
      Map<String, Map<String, dynamic>> builderConfigOverrides,
      Future until,
      {bool isReleaseMode = false}) {
    var watcherEnvironment = OverrideableEnvironment(environment,
        writer: _OnDeleteWriter(environment.writer, _expectedDeletes.add));
    var firstBuildCompleter = Completer<BuildResult>();
    currentBuild = firstBuildCompleter.future;
    var controller = StreamController<BuildResult>();

    Future<BuildResult> doBuild(List<List<AssetChange>> changes) async {
      assert(_build != null);
      _build.finalizedReader.reset();
      _logger.info('${'-' * 72}\n');
      _logger.info('Starting Build\n');
      var mergedChanges = _collectChanges(changes);

      _expectedDeletes.clear();
      if (!options.skipBuildScriptCheck) {
        if (_build.buildScriptUpdates
            .hasBeenUpdated(mergedChanges.keys.toSet())) {
          _terminateCompleter.complete();
          _logger.severe('Terminating builds due to build script update');
          return BuildResult(BuildStatus.failure, []);
        }
      }
      return _build.run(mergedChanges);
    }

    var terminate = Future.any([until, _terminateCompleter.future]).then((_) {
      _logger.info('Terminating. No further builds will be scheduled\n');
    });

    Digest originalRootPackagesDigest;
    final rootPackagesId = AssetId(packageGraph.root.name, '.packages');

    // Start watching files immediately, before the first build is even started.
    var graphWatcher = PackageGraphWatcher(packageGraph,
        logger: _logger,
        watch: (node) =>
            PackageNodeWatcher(node, watch: _directoryWatcherFactory));
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
            return watcherEnvironment.reader
                .readAsBytes(rootPackagesId)
                .then((bytes) {
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
          await _build?.beforeExit();
          await controller.close();
          _logger.info('Builds finished. Safe to exit\n');
        });

    // Schedule the actual first build for the future so we can return the
    // stream synchronously.
    () async {
      await logTimedAsync(_logger, 'Waiting for all file watchers to be ready',
          () => graphWatcher.ready);
      originalRootPackagesDigest = md5
          .convert(await watcherEnvironment.reader.readAsBytes(rootPackagesId));

      BuildResult firstBuild;
      try {
        _build = await BuildImpl.create(
            options, watcherEnvironment, builders, builderConfigOverrides,
            isReleaseBuild: isReleaseMode);

        firstBuild = await _build.run({});
      } on CannotBuildException {
        firstBuild = BuildResult(BuildStatus.failure, []);
      }

      _reader = _build?.finalizedReader;
      _readyCompleter.complete(null);
      // It is possible this is already closed if the user kills the process
      // early, which results in an exception without this check.
      if (!controller.isClosed) controller.add(firstBuild);
      firstBuildCompleter.complete(firstBuild);
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
  final _packageBuildYamlRegexp = RegExp(r'^[a-z0-9_]+\.build\.yaml$');

  /// Checks if we should skip a watch event for this [change].
  bool _shouldProcess(AssetChange change) {
    assert(_readyCompleter.isCompleted);
    if (_isCacheFile(change) && !assetGraph.contains(change.id)) return false;
    var node = assetGraph.get(change.id);
    if (node != null) {
      if (!_willCreateOutputDirs && !node.isInteresting) return false;
      if (_isAddOrEditOnGeneratedFile(node, change.type)) return false;
    } else {
      // We don't care about deletes or modifications outside the asset graph.
      if (change.type != ChangeType.ADD) return false;
      if (!_targetGraph.anyMatchesAsset(change.id)) return false;
    }
    if (_isExpectedDelete(change)) return false;
    return true;
  }

  bool _isCacheFile(AssetChange change) => change.id.path.startsWith(cacheDir);

  bool _isAddOrEditOnGeneratedFile(AssetNode node, ChangeType changeType) =>
      node.isGenerated && changeType != ChangeType.REMOVE;

  bool _isExpectedDelete(AssetChange change) =>
      _expectedDeletes.remove(change.id);
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
            throw StateError(
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
            throw StateError(
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
