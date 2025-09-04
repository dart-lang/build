// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart';
import 'package:build_daemon/change_provider.dart';
import 'package:build_daemon/constants.dart';
import 'package:build_daemon/daemon_builder.dart';
import 'package:build_daemon/data/build_status.dart';
import 'package:build_daemon/data/build_target.dart' hide OutputLocation;
import 'package:build_daemon/data/server_log.dart';
import 'package:built_collection/built_collection.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:watcher/watcher.dart';

import '../asset/finalized_reader.dart';
import '../asset/reader_writer.dart';
import '../build_plan.dart';
import '../commands/build_filter.dart';
import '../commands/daemon_options.dart';
import '../generate/asset_tracker.dart' show AssetTracker;
import '../generate/build_directory.dart';
import '../generate/build_result.dart' as core;
import '../generate/build_series.dart';
import '../logging/build_log.dart';
import '../watcher/asset_change.dart';
import '../watcher/change_filter.dart';
import '../watcher/collect_changes.dart';
import '../watcher/graph_watcher.dart';
import '../watcher/node_watcher.dart';
import 'change_providers.dart';

/// A Daemon Builder that builds with `build_runner`.
class BuildRunnerDaemonBuilder implements DaemonBuilder {
  final _buildResults = StreamController<BuildResults>();

  final BuildPlan _buildPlan;
  final BuildSeries _buildSeries;
  final StreamController<ServerLog> _outputStreamController;
  final ChangeProvider changeProvider;

  Completer<void>? _buildingCompleter;

  @override
  final Stream<ServerLog> logs;

  BuildRunnerDaemonBuilder._(
    this._buildPlan,
    this._buildSeries,
    this._outputStreamController,
    this.changeProvider,
  ) : logs = _outputStreamController.stream.asBroadcastStream();

  /// Returns a future that completes when the current build is complete, or
  /// `null` if there is no active build.
  Future<void>? get building => _buildingCompleter?.future;

  @override
  Stream<BuildResults> get builds => _buildResults.stream;

  FinalizedReader get reader => _buildSeries.finalizedReader;

  final _buildScriptUpdateCompleter = Completer<void>();
  Future<void> get buildScriptUpdated => _buildScriptUpdateCompleter.future;

  String get _packageName => _buildPlan.packageGraph.root.name;

  @override
  Future<void> build(
    Set<BuildTarget> targets,
    Iterable<WatchEvent> fileChanges,
  ) async {
    var defaultTargets = targets.cast<DefaultBuildTarget>();
    var changes =
        fileChanges
            .map<AssetChange>(
              (change) => AssetChange(AssetId.parse(change.path), change.type),
            )
            .toList();

    if (!_buildPlan.buildOptions.skipBuildScriptCheck &&
        _buildSeries.buildScriptUpdates!.hasBeenUpdated(
          changes.map<AssetId>((change) => change.id).toSet(),
        )) {
      if (!_buildScriptUpdateCompleter.isCompleted) {
        _buildScriptUpdateCompleter.complete();
      }
      return;
    }
    var targetNames = targets.map((t) => t.target).toSet();
    _logMessage(Level.INFO, 'About to build ${targetNames.toList()}...');
    _signalStart(targetNames);
    var results = <BuildResult>[];
    var buildDirs = <BuildDirectory>{};
    var buildFilters = <BuildFilter>{};
    for (var target in defaultTargets) {
      OutputLocation? outputLocation;
      if (target.outputLocation != null) {
        final targetOutputLocation = target.outputLocation!;
        outputLocation = OutputLocation(
          targetOutputLocation.output,
          useSymlinks: targetOutputLocation.useSymlinks,
          hoist: targetOutputLocation.hoist,
        );
      }
      buildDirs.add(
        BuildDirectory(target.target, outputLocation: outputLocation),
      );
      if (target.buildFilters != null && target.buildFilters!.isNotEmpty) {
        buildFilters.addAll([
          for (var pattern in target.buildFilters!)
            BuildFilter.fromArg(pattern, _packageName),
        ]);
      } else {
        buildFilters
          ..add(BuildFilter.fromArg('package:*/**', _packageName))
          ..add(BuildFilter.fromArg('${target.target}/**', _packageName));
      }
    }
    Iterable<AssetId>? outputs;

    try {
      var mergedChanges = collectChanges([changes]);
      var result = await _buildSeries.run(
        mergedChanges,
        buildDirs: buildDirs.build(),
        buildFilters: buildFilters.build(),
      );
      var interestedInOutputs = targets.any(
        (e) => e is DefaultBuildTarget && e.reportChangedAssets,
      );

      if (interestedInOutputs) {
        outputs = {for (var change in changes) change.id, ...result.outputs};
      }

      for (var target in targets) {
        if (result.status == core.BuildStatus.success) {
          // TODO(grouma) - Can we notify if a target was cached?
          results.add(
            DefaultBuildResult((b) {
              b.status = BuildStatus.succeeded;
              b.target = target.target;
            }),
          );
        } else {
          results.add(
            DefaultBuildResult((b) {
              b.status = BuildStatus.failed;
              // TODO(grouma) - We should forward the error messages
              // instead.
              // We can use the AssetGraph and FailureReporter to provide
              // a better error message.;
              b.error = 'FailureType: ${result.failureType?.exitCode}';
              b.target = target.target;
            }),
          );
        }
      }
    } catch (e) {
      for (var target in targets) {
        results.add(
          DefaultBuildResult((b) {
            b.status = BuildStatus.failed;
            b.error = '$e';
            b.target = target.target;
          }),
        );
      }
      _logMessage(Level.SEVERE, 'Build Failed:\n${e.toString()}');
    }
    _signalEnd(results, outputs?.map((e) => e.uri));
  }

  @override
  Future<void> stop() async {
    await _buildSeries.beforeExit();
  }

  void _logMessage(Level level, String message) => _outputStreamController.add(
    ServerLog((b) {
      b.message = message;
      b.level = level;
    }),
  );

  void _signalEnd(
    Iterable<BuildResult> results, [
    Iterable<Uri>? changedAssets,
  ]) {
    _buildingCompleter!.complete();
    _buildResults.add(
      BuildResults((b) {
        b.results.addAll(results);

        if (changedAssets != null) {
          b.changedAssets.addAll(changedAssets);
        }
      }),
    );
  }

  void _signalStart(Iterable<String> targets) {
    _buildingCompleter = Completer();
    var results = <BuildResult>[];
    for (var target in targets) {
      results.add(
        DefaultBuildResult((b) {
          b.status = BuildStatus.started;
          b.target = target;
        }),
      );
    }
    _buildResults.add(BuildResults((b) => b..results.addAll(results)));
  }

  static Future<BuildRunnerDaemonBuilder> create({
    required BuildPlan buildPlan,
    required DaemonOptions daemonOptions,
  }) async {
    var expectedDeletes = <AssetId>{};
    var outputStreamController = StreamController<ServerLog>(sync: true);

    buildLog.configuration = buildLog.configuration.rebuild((b) {
      b.onLog = (record) {
        outputStreamController.add(ServerLog.fromLogRecord(record));
      };
    });
    buildPlan = buildPlan.copyWith(
      writer: (buildPlan.writer as ReaderWriter).copyWith(
        onDelete: expectedDeletes.add,
      ),
    );

    final buildSeries = await BuildSeries.create(buildPlan: buildPlan);

    // Only actually used for the AutoChangeProvider.
    Stream<List<WatchEvent>> graphEvents() => PackageGraphWatcher(
          buildPlan.packageGraph,
          watch: PackageNodeWatcher.new,
        )
        .watch()
        .asyncWhere(
          (change) => shouldProcess(
            change,
            buildSeries.assetGraph,
            buildPlan.targetGraph,
            // Assume we will create an outputDir.
            true,
            expectedDeletes,
            buildPlan.reader,
          ),
        )
        .map((data) => WatchEvent(data.type, '${data.id}'))
        .debounceBuffer(
          buildPlan.testingOverrides.debounceDelay ??
              const Duration(milliseconds: 250),
        );

    var changeProvider =
        daemonOptions.buildMode == BuildMode.Auto
            ? AutoChangeProviderImpl(graphEvents())
            : ManualChangeProviderImpl(
              AssetTracker(buildPlan.reader, buildPlan.targetGraph),
              buildSeries.assetGraph,
            );

    return BuildRunnerDaemonBuilder._(
      buildPlan,
      buildSeries,
      outputStreamController,
      changeProvider,
    );
  }
}
