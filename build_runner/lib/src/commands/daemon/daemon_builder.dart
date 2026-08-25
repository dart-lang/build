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

import '../../build/build_result.dart' as core;
import '../../build/build_series.dart';
import '../../build_plan/build_directory.dart';
import '../../build_plan/build_filter.dart';
import '../../build_plan/build_plan.dart';
import '../../logging/build_log.dart';
import '../daemon_options.dart';
import '../watch/asset_change.dart';
import '../watch/build_packages_watcher.dart';
import 'change_providers.dart';

/// A Daemon Builder that builds with `build_runner`.
class BuildRunnerDaemonBuilder implements DaemonBuilder {
  final _buildResults = StreamController<BuildResults>();

  final BuildPlan _buildPlan;
  final BuildSeries buildSeries;
  final StreamController<ServerLog> _outputStreamController;
  final ChangeProvider changeProvider;
  final DaemonOptions daemonOptions;

  final Map<BuildTarget, BuildResult> _lastResultByTarget = {};

  Completer<void>? _buildingCompleter;

  @override
  final Stream<ServerLog> logs;

  BuildRunnerDaemonBuilder._(
    this._buildPlan,
    this.buildSeries,
    this._outputStreamController,
    this.changeProvider,
    this.daemonOptions,
  ) : logs = _outputStreamController.stream.asBroadcastStream();

  bool get _isAutoBuild => daemonOptions.buildMode == BuildMode.Auto;

  /// Returns a future that completes when the current build is complete, or
  /// `null` if there is no active build.
  Future<void>? get building => _buildingCompleter?.future;

  @override
  Stream<BuildResults> get builds => _buildResults.stream;

  final _buildScriptUpdateCompleter = Completer<void>();
  Future<void> get buildScriptUpdated => _buildScriptUpdateCompleter.future;

  String get _currentPackageName =>
      _buildPlan.buildSpec.buildPackages.currentPackage;

  @override
  Future<void> build(
    Set<BuildTarget> targets,
    Iterable<WatchEvent> fileChanges,
  ) async {
    if (targets.isEmpty) return;

    final defaultTargets = targets.cast<DefaultBuildTarget>();
    final Set<AssetId> updates;
    final Set<AssetId> consumedRejected;

    if (_isAutoBuild) {
      // In auto build mode, an empty changes list indicates an explicit build
      // request as distinct from a file watch based request.
      final isExplicitBuild = fileChanges.isEmpty;
      final autoBuild = await _prepareAutoBuild(
        targets,
        fileChanges,
        isExplicitBuild: isExplicitBuild,
      );
      if (autoBuild == null) return;
      updates = autoBuild.updates;
      consumedRejected = autoBuild.consumedRejected;
    } else {
      updates = fileChanges.map((change) => AssetId.parse(change.path)).toSet();
      consumedRejected = const {};
    }

    final targetNames = targets.map((t) => t.target).toSet();
    final interestedInOutputs = targets.any(
      (e) => e is DefaultBuildTarget && e.reportChangedAssets,
    );

    _logMessage(Level.INFO, 'About to build ${targetNames.toList()}...');
    _signalStart(targetNames);
    final results = <BuildResult>[];
    final buildDirs = <BuildDirectory>{};
    final buildFilters = <BuildFilter>{};
    for (final target in defaultTargets) {
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
          for (final pattern in target.buildFilters!)
            BuildFilter.fromArg(
              arg: pattern,
              currentPackage: _currentPackageName,
            ),
        ]);
      } else {
        buildFilters
          ..add(
            BuildFilter.fromArg(
              arg: 'package:*/**',
              currentPackage: _currentPackageName,
            ),
          )
          ..add(
            BuildFilter.fromArg(
              arg: '${target.target}/**',
              currentPackage: _currentPackageName,
            ),
          );
      }
    }
    Iterable<AssetId>? outputs;

    try {
      final result = await buildSeries.run(
        updates,
        recentlyBootstrapped: false,
        buildDirs: buildDirs.build(),
        buildFilters: buildFilters.build(),
      );
      if (result.failureType == core.FailureType.buildScriptChanged) {
        if (!_buildScriptUpdateCompleter.isCompleted) {
          _buildScriptUpdateCompleter.complete();
        }
        return;
      }

      if (interestedInOutputs) {
        outputs = {...updates, ...consumedRejected, ...result.outputs};
      }

      for (final target in targets) {
        if (result.status == core.BuildStatus.success) {
          final targetResult = DefaultBuildResult((b) {
            b.status = BuildStatus.succeeded;
            b.target = target.target;
          });
          _lastResultByTarget[target] = targetResult;
          results.add(targetResult);
        } else {
          final targetResult = DefaultBuildResult((b) {
            b.status = BuildStatus.failed;
            b.error = 'FailureType: ${result.failureType?.exitCode}';
            b.target = target.target;
          });
          _lastResultByTarget[target] = targetResult;
          results.add(targetResult);
        }
      }
    } catch (e) {
      for (final target in targets) {
        final targetResult = DefaultBuildResult((b) {
          b.status = BuildStatus.failed;
          b.error = '$e';
          b.target = target.target;
        });
        _lastResultByTarget[target] = targetResult;
        results.add(targetResult);
      }
      _logMessage(Level.SEVERE, 'Build Failed:\n${e.toString()}');
    }
    _signalEnd(results, outputs?.map((e) => e.uri));
  }

  @override
  Future<void> stop() async {
    await buildSeries.close();
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
    final results = <BuildResult>[];
    for (final target in targets) {
      results.add(
        DefaultBuildResult((b) {
          b.status = BuildStatus.started;
          b.target = target;
        }),
      );
    }
    _buildResults.add(BuildResults((b) => b..results.addAll(results)));
  }

  /// Prepares auto build updates by filtering [fileChanges] and handling
  /// unbuilt sources consumed outside the build.
  ///
  /// In auto build mode, incoming file changes are filtered into accepted build
  /// inputs and rejected changes.
  ///
  /// Rejected changes that were read or digested outside the build, for example
  /// by a development server, require notifying targets even though no build
  /// steps need to run.
  ///
  /// If only consumed rejected changes occurred and all targets have cached
  /// results, synthetic results are emitted immediately without rerunning the
  /// build.
  ///
  /// Returns null if no build is required or if synthetic results were already
  /// emitted.
  Future<({Set<AssetId> updates, Set<AssetId> consumedRejected})?>
  _prepareAutoBuild(
    Set<BuildTarget> targets,
    Iterable<WatchEvent> fileChanges, {
    required bool isExplicitBuild,
  }) async {
    final assetChanges = [
      for (final change in fileChanges)
        AssetChange(AssetId.parse(change.path), change.type),
    ];
    final filtered = await buildSeries.filterChanges(assetChanges);
    var consumedRejected = <AssetId>{};

    if (!buildSeries.firstBuild) {
      final lastResult = await buildSeries.currentBuildResult;
      final reader = lastResult.buildOutputReader;
      consumedRejected = filtered.rejected
          .where(
            (change) =>
                reader?.wasSourceConsumedOutsideBuild(change.id) ?? false,
          )
          .map((change) => change.id)
          .toSet();

      // Do nothing if it's not an explicit build and there are neither accepted
      // changes nor consumed rejected changes.
      if (!isExplicitBuild &&
          filtered.accepted.isEmpty &&
          consumedRejected.isEmpty) {
        return null;
      }

      // If only consumed rejected changes exist and all targets have a cached
      // result, emit synthetic results.
      if (filtered.accepted.isEmpty &&
          targets.every(_lastResultByTarget.containsKey)) {
        _emitSyntheticResults(targets, consumedRejected);
        return null;
      }
    }

    return (
      updates: filtered.accepted.map((c) => c.id).toSet(),
      consumedRejected: consumedRejected,
    );
  }

  void _emitSyntheticResults(
    Set<BuildTarget> targets,
    Set<AssetId> consumedRejected,
  ) {
    final targetNames = targets.map((t) => t.target).toSet();
    final interestedInOutputs = targets.any(
      (e) => e is DefaultBuildTarget && e.reportChangedAssets,
    );
    _signalStart(targetNames);
    final results = [
      for (final target in targets) _lastResultByTarget[target]!,
    ];
    final outputs = interestedInOutputs ? consumedRejected : null;
    _signalEnd(results, outputs?.map((e) => e.uri));
  }

  static Future<BuildRunnerDaemonBuilder> create({
    required BuildPlan buildPlan,
    required DaemonOptions daemonOptions,
  }) async {
    final outputStreamController = StreamController<ServerLog>(sync: true);

    buildLog.configuration = buildLog.configuration.rebuild((b) {
      b.onLog = (record) {
        outputStreamController.add(ServerLog.fromLogRecord(record));
      };
    });

    final buildSeries = BuildSeries(buildPlan);

    // Only actually used for the AutoChangeProvider.
    Stream<List<WatchEvent>> graphEvents() =>
        BuildPackagesWatcher(buildPlan.buildSpec.buildPackages)
            .watch()
            .debounceBuffer(
              buildPlan.buildSpec.testingOverrides.debounceDelay ??
                  const Duration(milliseconds: 250),
            )
            .map(
              (changes) => changes
                  .map((change) => WatchEvent(change.type, '${change.id}'))
                  .toList(),
            );

    final changeProvider = daemonOptions.buildMode == BuildMode.Auto
        ? AutoChangeProviderImpl(graphEvents())
        : ManualChangeProviderImpl(buildSeries.checkForChanges);

    return BuildRunnerDaemonBuilder._(
      buildPlan,
      buildSeries,
      outputStreamController,
      changeProvider,
      daemonOptions,
    );
  }
}
