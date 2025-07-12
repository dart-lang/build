// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:build/build.dart';
import 'package:build_config/build_config.dart';
import 'package:build_runner_core/build_runner_core.dart';
// ignore: implementation_imports
import 'package:build_runner_core/src/asset_graph/graph.dart';
// ignore: implementation_imports
import 'package:build_runner_core/src/generate/build_series.dart';
import 'package:crypto/crypto.dart';
import 'package:logging/logging.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:watcher/watcher.dart';

import '../build_script_generate/build_process_state.dart';
import '../package_graph/build_config_overrides.dart';
import '../server/server.dart';
import '../watcher/asset_change.dart';
import '../watcher/change_filter.dart';
import '../watcher/collect_changes.dart';
import '../watcher/graph_watcher.dart';
import '../watcher/node_watcher.dart';
import 'terminator.dart';

Future<ServeHandler> watch(
  List<BuilderApplication> builders, {
  bool? deleteFilesByDefault,
  bool? assumeTty,
  String? configKey,
  PackageGraph? packageGraph,
  AssetReader? reader,
  RunnerAssetWriter? writer,
  Resolvers? resolvers,
  void Function(LogRecord)? onLog,
  Duration? debounceDelay,
  required DirectoryWatcher Function(String) directoryWatcherFactory,
  Stream<ProcessSignal>? terminateEventStream,
  bool? skipBuildScriptCheck,
  bool? enableLowResourcesMode,
  Map<String, BuildConfig>? overrideBuildConfig,
  Set<BuildDirectory>? buildDirs,
  bool? outputSymlinksOnly,
  bool? trackPerformance,
  bool? verbose,
  Map<String, Map<String, dynamic>>? builderConfigOverrides,
  bool? isReleaseBuild,
  String? logPerformanceDir,
  Set<BuildFilter>? buildFilters,
}) async {
  builderConfigOverrides ??= const {};
  buildDirs ??= <BuildDirectory>{};
  buildFilters ??= <BuildFilter>{};
  debounceDelay ??= const Duration(milliseconds: 250);
  deleteFilesByDefault ??= false;
  enableLowResourcesMode ??= false;
  outputSymlinksOnly ??= false;
  packageGraph ??= await PackageGraph.forThisPackage();
  skipBuildScriptCheck ??= false;
  trackPerformance ??= false;
  verbose ??= false;

  var environment = BuildEnvironment(
    packageGraph,
    assumeTty: assumeTty,
    outputSymlinksOnly: outputSymlinksOnly,
    reader: reader,
    writer: writer,
  );
  buildLog.configuration = buildLog.configuration.rebuild((b) {
    b.mode = BuildLogMode.build;
    b.verbose = verbose;
    b.onLog = onLog;
  });
  overrideBuildConfig ??= await findBuildConfigOverrides(
    packageGraph,
    environment.reader,
    configKey: configKey,
  );
  var options = await BuildOptions.create(
    packageGraph: packageGraph,
    reader: environment.reader,
    deleteFilesByDefault: deleteFilesByDefault,
    overrideBuildConfig: overrideBuildConfig,
    debounceDelay: debounceDelay,
    skipBuildScriptCheck: skipBuildScriptCheck,
    enableLowResourcesMode: enableLowResourcesMode,
    trackPerformance: trackPerformance,
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
    buildDirs.any((target) => target.outputLocation?.path.isNotEmpty ?? false),
    buildDirs,
    buildFilters,
    isReleaseMode: isReleaseBuild ?? false,
  );

  unawaited(
    watch.buildResults.drain<void>().then((_) async {
      await terminator.cancel();
    }),
  );

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
  String? configKey,
  bool willCreateOutputDirs,
  Set<BuildDirectory> buildDirs,
  Set<BuildFilter> buildFilters, {
  bool isReleaseMode = false,
}) => WatchImpl(
  options,
  environment,
  builders,
  builderConfigOverrides,
  until,
  directoryWatcherFactory,
  configKey,
  willCreateOutputDirs,
  buildDirs,
  buildFilters,
  isReleaseMode: isReleaseMode,
);

class WatchImpl implements BuildState {
  BuildSeries? _buildSeries;

  AssetGraph? get assetGraph => _buildSeries?.assetGraph;

  final String? _configKey;

  /// Delay to wait for more file watcher events.
  final Duration _debounceDelay;

  /// Injectable factory for creating directory watchers.
  final DirectoryWatcher Function(String) _directoryWatcherFactory;

  /// Whether or not we will be creating any output directories.
  ///
  /// If not, then we don't care about source edits that don't have outputs.
  final bool _willCreateOutputDirs;

  /// Should complete when we need to kill the build.
  final _terminateCompleter = Completer<void>();

  /// The [PackageGraph] for the current program.
  final PackageGraph packageGraph;

  /// The directories to build upon file changes and where to output them.
  final Set<BuildDirectory> _buildDirs;

  /// Filters for specific files to build.
  final Set<BuildFilter> _buildFilters;

  @override
  Future<BuildResult>? currentBuild;

  /// Pending expected delete events from the build.
  final Set<AssetId> _expectedDeletes = <AssetId>{};

  final _readerCompleter = Completer<FinalizedReader>();

  /// Completes with an error if we fail to initialize.
  Future<FinalizedReader> get reader => _readerCompleter.future;

  WatchImpl(
    BuildOptions options,
    BuildEnvironment environment,
    List<BuilderApplication> builders,
    Map<String, Map<String, dynamic>> builderConfigOverrides,
    Future until,
    this._directoryWatcherFactory,
    this._configKey,
    this._willCreateOutputDirs,
    this._buildDirs,
    this._buildFilters, {
    bool isReleaseMode = false,
  }) : _debounceDelay = options.debounceDelay,
       packageGraph = options.packageGraph {
    buildResults =
        _run(
          options,
          environment,
          builders,
          builderConfigOverrides,
          until,
          isReleaseMode: isReleaseMode,
        ).asBroadcastStream();
  }

  @override
  late final Stream<BuildResult> buildResults;

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
    Future until, {
    bool isReleaseMode = false,
  }) {
    // TODO(davidmorgan): simplify setup.
    var watcherEnvironment = environment.copyWith(
      writer: (environment.writer as ReaderWriter).copyWith(
        onDelete: _expectedDeletes.add,
      ),
      reader:
          environment.reader is ReaderWriter
              ? (environment.reader as ReaderWriter).copyWith(
                onDelete: _expectedDeletes.add,
              )
              : environment.reader,
    );
    var firstBuildCompleter = Completer<BuildResult>();
    currentBuild = firstBuildCompleter.future;
    var controller = StreamController<BuildResult>();

    Future<BuildResult> doBuild(List<List<AssetChange>> changes) async {
      buildLog.nextBuild();
      var build = _buildSeries!;
      var mergedChanges = collectChanges(changes);

      _expectedDeletes.clear();
      if (!options.skipBuildScriptCheck) {
        if (build.buildScriptUpdates!.hasBeenUpdated(
          mergedChanges.keys.toSet(),
        )) {
          _terminateCompleter.complete();
          buildLog.error('Terminating builds due to build script update.');
          return BuildResult(
            BuildStatus.failure,
            [],
            failureType: FailureType.buildScriptChanged,
          );
        }
      }
      return build.run(
        mergedChanges,
        buildDirs: _buildDirs,
        buildFilters: _buildFilters,
      );
    }

    var terminate = Future.any([until, _terminateCompleter.future]).then((_) {
      buildLog.info('Terminating. No further builds will be scheduled.');
    });

    Digest? originalRootPackageConfigDigest;
    final rootPackageConfigId = AssetId(
      packageGraph.root.name,
      '.dart_tool/package_config.json',
    );

    // Start watching files immediately, before the first build is even started.
    var graphWatcher = PackageGraphWatcher(
      packageGraph,
      watch:
          (node) => PackageNodeWatcher(node, watch: _directoryWatcherFactory),
    );
    graphWatcher
        .watch()
        .asyncMap<AssetChange>((change) {
          // Delay any events until the first build is completed.
          if (firstBuildCompleter.isCompleted) return change;
          return firstBuildCompleter.future.then((_) => change);
        })
        .asyncMap<AssetChange>((change) {
          var id = change.id;
          if (id == rootPackageConfigId) {
            var digest = originalRootPackageConfigDigest!;
            // Kill future builds if the root packages file changes.
            //
            // We retry the reads for a little bit to handle the case where a
            // user runs `pub get` and it hasn't been re-written yet.
            return _readOnceExists(id, watcherEnvironment.reader).then((bytes) {
              if (md5.convert(bytes) != digest) {
                _terminateCompleter.complete();
                buildLog.error(
                  'Terminating builds due to package graph update.',
                );
              }
              return change;
            });
          } else if (_isBuildYaml(id) ||
              _isConfiguredBuildYaml(id) ||
              _isPackageBuildYamlOverride(id)) {
            controller.add(
              BuildResult(
                BuildStatus.failure,
                [],
                failureType: FailureType.buildConfigChanged,
              ),
            );

            // Kill future builds if the build.yaml files change.
            _terminateCompleter.complete();
            buildLog.error(
              'Terminating builds due to ${id.package}:${id.path} update.',
            );
          }
          return change;
        })
        .asyncWhere((change) {
          assert(_readerCompleter.isCompleted);
          return shouldProcess(
            change,
            assetGraph!,
            options,
            _willCreateOutputDirs,
            _expectedDeletes,
            watcherEnvironment.reader,
          );
        })
        .debounceBuffer(_debounceDelay)
        .takeUntil(terminate)
        .asyncMapBuffer(
          (changes) =>
              currentBuild = doBuild(changes)
                ..whenComplete(() => currentBuild = null),
        )
        .listen((BuildResult result) {
          if (controller.isClosed) return;
          controller.add(result);
        })
        .onDone(() async {
          await currentBuild;
          await _buildSeries?.beforeExit();
          if (!controller.isClosed) await controller.close();
          buildLog.info('Builds finished. Safe to exit\n');
        });

    // Schedule the actual first build for the future so we can return the
    // stream synchronously.
    () async {
      buildLog.doing('Waiting for file watchers to be ready.');
      await graphWatcher.ready;
      if (await watcherEnvironment.reader.canRead(rootPackageConfigId)) {
        originalRootPackageConfigDigest = md5.convert(
          await watcherEnvironment.reader.readAsBytes(rootPackageConfigId),
        );
      } else {
        buildLog.warning(
          'Root package config not readable, manual restarts will be needed '
          'after running `pub upgrade`.',
        );
      }

      BuildResult firstBuild;
      BuildSeries? build;
      try {
        build =
            _buildSeries = await BuildSeries.create(
              options,
              watcherEnvironment,
              builders,
              builderConfigOverrides,
              isReleaseBuild: isReleaseMode,
            );

        firstBuild = await build.run(
          {},
          buildDirs: _buildDirs,
          buildFilters: _buildFilters,
        );
      } on CannotBuildException catch (e, s) {
        _terminateCompleter.complete();

        firstBuild = BuildResult(BuildStatus.failure, []);
        _readerCompleter.completeError(e, s);
      } on BuildScriptChangedException catch (e, s) {
        _terminateCompleter.complete();

        firstBuild = BuildResult(
          BuildStatus.failure,
          [],
          failureType: FailureType.buildScriptChanged,
        );
        _readerCompleter.completeError(e, s);
      }
      if (build != null) {
        assert(!_readerCompleter.isCompleted);
        _readerCompleter.complete(build.finalizedReader);
      }
      // It is possible this is already closed if the user kills the process
      // early, which results in an exception without this check.
      if (!controller.isClosed) controller.add(firstBuild);
      firstBuildCompleter.complete(firstBuild);
    }();

    return controller.stream;
  }

  bool _isBuildYaml(AssetId id) => id.path == 'build.yaml';
  bool _isConfiguredBuildYaml(AssetId id) =>
      id.package == packageGraph.root.name &&
      id.path == 'build.$_configKey.yaml';
  bool _isPackageBuildYamlOverride(AssetId id) =>
      id.package == packageGraph.root.name &&
      id.path.contains(_packageBuildYamlRegexp);
  final _packageBuildYamlRegexp = RegExp(r'^[a-z0-9_]+\.build\.yaml$');
}

/// Reads [id] using [reader], waiting for it to exist for up to 1 second.
///
/// If it still doesn't exist after 1 second then throws an
/// [AssetNotFoundException].
Future<List<int>> _readOnceExists(AssetId id, AssetReader reader) async {
  var watch = Stopwatch()..start();
  var tryAgain = true;
  while (tryAgain) {
    if (await reader.canRead(id)) {
      return reader.readAsBytes(id);
    }
    tryAgain = watch.elapsedMilliseconds < 1000;
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  throw AssetNotFoundException(id);
}
