// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart';
import 'package:crypto/crypto.dart';
import 'package:stream_transform/stream_transform.dart';

import '../../build/asset_graph/graph.dart';
import '../../build/build_result.dart';
import '../../build/build_series.dart';
import '../../build_plan/build_options.dart';
import '../../build_plan/build_plan.dart';
import '../../build_plan/package_graph.dart';
import '../../build_plan/testing_overrides.dart';
import '../../io/build_output_reader.dart';
import '../../io/reader_writer.dart';
import '../../logging/build_log.dart';
import 'asset_change.dart';
import 'change_filter.dart';
import 'collect_changes.dart';
import 'graph_watcher.dart';
import 'node_watcher.dart';

class Watcher {
  late final BuildPlan buildPlan;

  BuildSeries? _buildSeries;

  AssetGraph? get assetGraph => _buildSeries?.assetGraph;

  /// Whether or not we will be creating any output directories.
  ///
  /// If not, then we don't care about source edits that don't have outputs.
  final bool willCreateOutputDirs;

  /// Should complete when we need to kill the build.
  final _terminateCompleter = Completer<void>();

  late Future<BuildResult> currentBuildResult;

  /// Pending expected delete events from the build.
  final Set<AssetId> _expectedDeletes = <AssetId>{};

  Watcher({
    required BuildPlan buildPlan,
    required Future until,
    required this.willCreateOutputDirs,
  }) {
    this.buildPlan = buildPlan.copyWith(
      readerWriter: buildPlan.readerWriter.copyWith(
        onDelete: _expectedDeletes.add,
      ),
    );
    buildResults = _run(until).asBroadcastStream();
  }

  BuildOptions get buildOptions => buildPlan.buildOptions;
  TestingOverrides get testingOverrides => buildPlan.testingOverrides;
  PackageGraph get packageGraph => buildPlan.packageGraph;
  ReaderWriter get readerWriter => buildPlan.readerWriter;

  late final Stream<BuildResult> buildResults;

  /// Runs a build any time relevant files change.
  ///
  /// Only one build will run at a time, and changes are batched.
  ///
  /// File watchers are scheduled synchronously.
  Stream<BuildResult> _run(Future until) {
    final firstBuildCompleter = Completer<BuildResult>();
    currentBuildResult = firstBuildCompleter.future;
    final controller = StreamController<BuildResult>();

    Future<BuildResult> doBuild(List<List<AssetChange>> changes) async {
      buildLog.nextBuild();
      final build = _buildSeries!;
      final mergedChanges = collectChanges(changes);

      _expectedDeletes.clear();
      if (!buildOptions.skipBuildScriptCheck) {
        if (build.buildScriptUpdates!.hasBeenUpdated(
          mergedChanges.keys.toSet(),
        )) {
          _terminateCompleter.complete();
          buildLog.error('Terminating builds due to build script update.');
          return BuildResult(
            status: BuildStatus.failure,
            failureType: FailureType.buildScriptChanged,
            buildOutputReader: BuildOutputReader(
              buildPlan: buildPlan,
              readerWriter: readerWriter,
              assetGraph: assetGraph!,
            ),
          );
        }
      }
      return build.run(mergedChanges);
    }

    final terminate = Future.any([until, _terminateCompleter.future]).then((_) {
      buildLog.info('Terminating. No further builds will be scheduled.');
    });

    Digest? originalRootPackageConfigDigest;
    final rootPackageConfigId = AssetId(
      packageGraph.root.name,
      '.dart_tool/package_config.json',
    );

    // Start watching files immediately, before the first build is even started.
    final graphWatcher = PackageGraphWatcher(
      packageGraph,
      watch:
          (node) => PackageNodeWatcher(
            node,
            watch: testingOverrides.directoryWatcherFactory,
          ),
    );
    graphWatcher
        .watch()
        .asyncMap<AssetChange>((change) {
          // Delay any events until the first build is completed.
          if (firstBuildCompleter.isCompleted) return change;
          return firstBuildCompleter.future.then((_) => change);
        })
        .asyncMap<AssetChange>((change) {
          final id = change.id;
          if (id == rootPackageConfigId) {
            final digest = originalRootPackageConfigDigest!;
            // Kill future builds if the root packages file changes.
            //
            // We retry the reads for a little bit to handle the case where a
            // user runs `pub get` and it hasn't been re-written yet.
            return _readOnceExists(id, readerWriter).then((bytes) {
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
                status: BuildStatus.failure,
                failureType: FailureType.buildConfigChanged,
                buildOutputReader: BuildOutputReader.empty(),
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
          return shouldProcess(
            change,
            assetGraph!,
            buildPlan.targetGraph,
            willCreateOutputDirs,
            _expectedDeletes,
            readerWriter,
          );
        })
        .debounceBuffer(
          testingOverrides.debounceDelay ?? const Duration(milliseconds: 250),
        )
        .takeUntil(terminate)
        .asyncMapBuffer((changes) => currentBuildResult = doBuild(changes))
        .listen((BuildResult result) {
          if (controller.isClosed) return;
          controller.add(result);
        })
        .onDone(() async {
          await currentBuildResult;
          await _buildSeries?.beforeExit();
          if (!controller.isClosed) await controller.close();
          buildLog.info('Builds finished. Safe to exit\n');
        });

    // Schedule the actual first build for the future so we can return the
    // stream synchronously.
    () async {
      buildLog.doing('Waiting for file watchers to be ready.');
      await graphWatcher.ready;
      if (await readerWriter.canRead(rootPackageConfigId)) {
        originalRootPackageConfigDigest = md5.convert(
          await readerWriter.readAsBytes(rootPackageConfigId),
        );
      } else {
        buildLog.warning(
          'Root package config not readable, manual restarts will be needed '
          'after running `pub upgrade`.',
        );
      }

      BuildResult firstBuild;
      BuildSeries? build;
      build = _buildSeries = await BuildSeries.create(buildPlan: buildPlan);
      firstBuild = await build.run({});
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
      id.path == 'build.${buildOptions.configKey}.yaml';
  bool _isPackageBuildYamlOverride(AssetId id) =>
      id.package == packageGraph.root.name &&
      id.path.contains(_packageBuildYamlRegexp);
  final _packageBuildYamlRegexp = RegExp(r'^[a-z0-9_]+\.build\.yaml$');
}

/// Reads [id] using [readerWriter], waiting for it to exist for up to 1 second.
///
/// If it still doesn't exist after 1 second then throws an
/// [AssetNotFoundException].
Future<List<int>> _readOnceExists(AssetId id, ReaderWriter readerWriter) async {
  final watch = Stopwatch()..start();
  var tryAgain = true;
  while (tryAgain) {
    if (await readerWriter.canRead(id)) {
      return readerWriter.readAsBytes(id);
    }
    tryAgain = watch.elapsedMilliseconds < 1000;
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  throw AssetNotFoundException(id);
}
