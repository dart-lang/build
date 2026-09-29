// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:built_collection/built_collection.dart';
import 'package:stream_transform/stream_transform.dart';

import '../../bootstrap/build_process_state.dart';
import '../../build/build_result.dart';
import '../../build/build_series.dart';
import '../../build_plan/build_packages.dart';
import '../../build_plan/build_plan.dart';
import '../../logging/build_log.dart';
import 'asset_change.dart';
import 'build_package_watcher.dart';
import 'build_packages_watcher.dart';
import 'collect_changes.dart';
import 'filtered_changes.dart';

class Watcher {
  final BuildPlan _buildPlan;
  final BuildSeries _buildSeries;

  final StreamController<BuildResult> _buildResultsController =
      StreamController.broadcast();

  Watcher._(this._buildPlan, this._buildSeries);

  BuildPackages get buildPackages => _buildPlan.buildSpec.buildPackages;

  factory Watcher({required BuildPlan buildPlan, required Future<void> until}) {
    final buildSeries = BuildSeries(buildPlan);
    final result = Watcher._(buildPlan, buildSeries);
    result._run(until);
    return result;
  }

  Stream<BuildResult> get buildResults => _buildResultsController.stream;
  Future<BuildResult> get currentBuildResult => _buildSeries.currentBuildResult;

  /// Runs a build any time relevant files change.
  ///
  /// Only one build will run at a time, and changes are batched.
  ///
  /// File watchers are scheduled synchronously.
  void _run(Future<void> until) async {
    // If the BuildProcessLock is requested, finish the current build if there
    // is one then exit.
    final closeController = Completer<void>();
    buildProcessState.setLockRequestCallback(() {
      if (!closeController.isCompleted) {
        closeController.complete();
      }
    });
    final terminate = Future.any([until, closeController.future]);

    // Start watching files immediately, before the first build is even started.
    final packagesWatcher = BuildPackagesWatcher(
      _buildPlan.buildSpec.buildPackages,
      watch: (buildPackage) => BuildPackageWatcher(
        buildPackage,
        watch: _buildPlan.buildSpec.testingOverrides.directoryWatcherFactory,
      ),
    );
    packagesWatcher
        .watch()
        .asyncMap<AssetChange>((change) async {
          // Delay any events until the current build is completed.
          await currentBuildResult;
          return change;
        })
        .debounceBuffer(
          _buildPlan.buildSpec.testingOverrides.debounceDelay ??
              const Duration(milliseconds: 250),
        )
        .asyncMap(_buildSeries.filterChanges)
        .where((filtered) => filtered.isNotEmpty)
        .takeUntil(terminate)
        .asyncMapBuffer(_doBuildOrNotify)
        .drain<void>()
        .then((_) async {
          await currentBuildResult;
          await _buildSeries.close();
          await _buildResultsController.close();
          if (buildProcessState.isLockRequested()) {
            buildLog.flushAndPrint(
              'Exiting as requested by another build_runner process.',
            );
          }
        })
        .ignore();

    await packagesWatcher.ready;
    final initialResult = await _buildSeries.run(
      {},
      recentlyBootstrapped: true,
    );
    _buildResultsController.add(initialResult);
  }

  /// Runs a build if there are accepted changes, or emits a synthetic build
  /// result if only consumed rejected changes occurred.
  ///
  /// Accepted changes affect build outputs, so they trigger a new build.
  ///
  /// Rejected changes do not affect build outputs, but if they were read or
  /// digested outside the build, for example by an asset server, listeners need
  /// a notification that the files were updated.
  Future<void> _doBuildOrNotify(List<FilteredChanges> changesList) async {
    final allAccepted = [for (final c in changesList) ...c.accepted];
    final allRejected = [for (final c in changesList) ...c.rejected];

    if (allAccepted.isNotEmpty) {
      final mergedChanges = collectChanges([allAccepted]);
      final result = await _buildSeries.run(
        mergedChanges,
        recentlyBootstrapped: false,
      );
      _buildResultsController.add(result);
      return;
    }

    if (allRejected.isNotEmpty) {
      final lastResult = await currentBuildResult;
      final reader = lastResult.buildOutputReader;
      final consumedRejected = allRejected
          .where((c) => reader?.wasSourceConsumedOutsideBuild(c.id) ?? false)
          .toList();

      if (consumedRejected.isNotEmpty) {
        final syntheticResult = lastResult.copyWith(outputs: BuiltList());
        _buildResultsController.add(syntheticResult);
      }
    }
  }
}
