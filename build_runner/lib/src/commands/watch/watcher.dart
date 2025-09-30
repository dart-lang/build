// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart';
import 'package:stream_transform/stream_transform.dart';

import '../../build/build_result.dart';
import '../../build/build_series.dart';
import '../../build_plan/build_plan.dart';
import 'asset_change.dart';
import 'collect_changes.dart';
import 'graph_watcher.dart';
import 'node_watcher.dart';

class Watcher {
  final BuildPlan _buildPlan;
  final BuildSeries _buildSeries;

  /// Pending expected delete events from the build.
  final Set<AssetId> _expectedDeletes;

  Watcher._(this._buildPlan, this._buildSeries, this._expectedDeletes);

  factory Watcher({required BuildPlan buildPlan, required Future<void> until}) {
    final expectedDeletes = <AssetId>{};
    buildPlan = buildPlan.copyWith(
      readerWriter: buildPlan.readerWriter.copyWith(
        onDelete: expectedDeletes.add,
      ),
    );
    final buildSeries = BuildSeries(buildPlan);
    final result = Watcher._(buildPlan, buildSeries, expectedDeletes);
    result._run(until);
    return result;
  }

  Stream<BuildResult> get buildResults => _buildSeries.buildResults;
  Future<BuildResult> get currentBuildResult => _buildSeries.currentBuildResult;

  /// Runs a build any time relevant files change.
  ///
  /// Only one build will run at a time, and changes are batched.
  ///
  /// File watchers are scheduled synchronously.
  void _run(Future<void> until) async {
    final terminate = Future.any([until, _buildSeries.closing]);

    // Start watching files immediately, before the first build is even started.
    final graphWatcher = PackageGraphWatcher(
      _buildPlan.packageGraph,
      watch:
          (node) => PackageNodeWatcher(
            node,
            watch: _buildPlan.testingOverrides.directoryWatcherFactory,
          ),
    );
    graphWatcher
        .watch()
        .asyncMap<AssetChange>((change) async {
          // Delay any events until the current build is completed.
          await currentBuildResult;
          return change;
        })
        .debounceBuffer(
          _buildPlan.testingOverrides.debounceDelay ??
              const Duration(milliseconds: 250),
        )
        .asyncMap(
          (changes) => _buildSeries.filterChanges(changes, _expectedDeletes),
        )
        .where((changes) => changes.isNotEmpty)
        .takeUntil(terminate)
        .asyncMapBuffer(_doBuild)
        .drain<void>()
        .ignore();

    await graphWatcher.ready;
    await _buildSeries.run({});
  }

  Future<BuildResult> _doBuild(List<List<AssetChange>> changes) async {
    final mergedChanges = collectChanges(changes);
    _expectedDeletes.clear();
    final result = await _buildSeries.run(mergedChanges);
    return result;
  }
}
