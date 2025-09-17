// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart';
import 'package:stream_transform/stream_transform.dart';

import '../../build/asset_graph/graph.dart';
import '../../build/build_result.dart';
import '../../build/build_series.dart';
import '../../build_plan/build_options.dart';
import '../../build_plan/build_plan.dart';
import '../../build_plan/package_graph.dart';
import '../../build_plan/testing_overrides.dart';
import '../../exceptions.dart';
import '../../io/finalized_reader.dart';
import '../../io/reader_writer.dart';
import '../../logging/build_log.dart';
import 'asset_change.dart';
import 'change_filter.dart';
import 'collect_changes.dart';
import 'graph_watcher.dart';
import 'node_watcher.dart';

class Watcher implements BuildState {
  late final BuildPlan buildPlan;

  BuildSeries? _buildSeries;

  AssetGraph? get assetGraph => _buildSeries?.assetGraph;

  /// Whether or not we will be creating any output directories.
  ///
  /// If not, then we don't care about source edits that don't have outputs.
  final bool willCreateOutputDirs;

  /// Should complete when we need to kill the build.
  final _terminateCompleter = Completer<void>();

  @override
  Future<BuildResult>? currentBuild;

  /// Pending expected delete events from the build.
  final Set<AssetId> _expectedDeletes = <AssetId>{};

  final _readerCompleter = Completer<FinalizedReader>();

  /// Completes with an error if we fail to initialize.
  Future<FinalizedReader> get finalizedReader => _readerCompleter.future;

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

  @override
  late final Stream<BuildResult> buildResults;

  /// Runs a build any time relevant files change.
  ///
  /// Only one build will run at a time, and changes are batched.
  ///
  /// File watchers are scheduled synchronously.
  Stream<BuildResult> _run(Future until) {
    final firstBuildCompleter = Completer<BuildResult>();
    currentBuild = firstBuildCompleter.future;
    final controller = StreamController<BuildResult>();

    Future<BuildResult> doBuild(List<List<AssetChange>> changes) async {
      buildLog.nextBuild();
      final build = _buildSeries!;
      final mergedChanges = collectChanges(changes);

      buildLog.debug('changes: $changes');

      _expectedDeletes.clear();
      return build.run(mergedChanges);
    }

    final terminate = Future.any([until, _terminateCompleter.future]);

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
        .where((event) {
          return event.id.path != '.dart_tool/build/entrypoint/state.json';
        })
        .debounceBuffer(
          testingOverrides.debounceDelay ?? const Duration(milliseconds: 250),
        )
        .asyncMap<List<AssetChange>>((changes) async {
          if (await buildPlan.bootstrapper.needsRebuild()) {
            _terminateCompleter.complete();
            controller.add(
              BuildResult(
                BuildStatus.failure,
                [],
                failureType: FailureType.buildScriptChanged,
              ),
            );
          }
          return changes;
        })
        .asyncMap((changes) async {
          assert(_readerCompleter.isCompleted);
          final result = <AssetChange>[];
          for (final change in changes) {
            if (await shouldProcess(
              change,
              assetGraph!,
              buildPlan.targetGraph,
              willCreateOutputDirs,
              _expectedDeletes,
              readerWriter,
            )) {
              result.add(change);
            }
          }
          return result;
        })
        .where((changes) => changes.isNotEmpty)
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

      BuildResult firstBuild;
      BuildSeries? build;
      try {
        build = _buildSeries = await BuildSeries.create(buildPlan: buildPlan);

        firstBuild = await build.run({});
      } on CannotBuildException catch (e, s) {
        _terminateCompleter.complete();

        firstBuild = BuildResult(BuildStatus.failure, []);
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
}
