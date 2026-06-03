// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart';
import 'package:built_collection/built_collection.dart';
import 'package:watcher/watcher.dart';

import '../build_plan/build_directory.dart';
import '../build_plan/build_filter.dart';
import '../build_plan/build_plan.dart';
import '../commands/watch/asset_change.dart';
import '../constants.dart';
import '../io/asset_tracker.dart';

import '../logging/build_log.dart';
import 'build.dart';
import 'build_result.dart';
import 'build_state/build_state.dart';

/// A series of builds with the same configuration.
///
/// Changes to inputs are tracked to determine what build steps need to rerun
/// each time, for fast "incremental" builds.
///
/// This happens either across multiple invocations of `build_runner build` or
/// within one long-running `build_runner watch` or `build_runner serve`.
///
/// In both cases, the `BuildState` is serialized after the build, to give the
/// starting state for the next `build_runner build`. For `watch` and `serve`
/// this serialized state is not actually used: the `BuildState` instance
/// already in memory is used directly.
class BuildSeries {
  final ResourceManager _resourceManager = ResourceManager();
  BuildPlan _buildPlan;

  final StreamController<BuildResult> _buildResultsController =
      StreamController.broadcast();

  final Completer<void> _closingCompleter = Completer();

  /// Whether the next build is the first build.
  bool firstBuild = true;

  BuildSeries._({required BuildPlan buildPlan}) : _buildPlan = buildPlan;

  factory BuildSeries(BuildPlan buildPlan) {
    return BuildSeries._(buildPlan: buildPlan);
  }

  /// Broadcast stream of build results.
  Stream<BuildResult> get buildResults => _buildResultsController.stream;
  Future<BuildResult>? _currentBuildResult;

  /// A future that completes when [close] is called.
  ///
  /// Then, no further builds are allowed.
  Future<void> get closing => _closingCompleter.future;

  /// Filters [changes] to only changes that might trigger a build.
  ///
  /// Pass expected deletes in [expectedDeletes]. Expected deletes do not
  /// trigger a build. A delete that matches is removed from the set.
  Future<List<AssetChange>> filterChanges(
    List<AssetChange> changes,
    Set<AssetId> expectedDeletes,
  ) async {
    final result = <AssetChange>[];
    for (final change in changes) {
      final id = change.id;

      // Changes to the entrypoint are handled via depfiles.
      if (_buildPlan.bootstrapper.isCompileDependency(
        _buildPlan.buildPackages.pathFor(id, hide: false),
      )) {
        result.add(change);
        continue;
      }
      if (id.path.startsWith(entrypointDirectoryPath)) {
        continue;
      }

      // Ignore any expected delete once.
      if (change.type == ChangeType.REMOVE && expectedDeletes.remove(id)) {
        continue;
      }

      if (_isBuildConfiguration(id)) {
        result.add(change);
        continue;
      }

      final isFile =
          _buildPlan.previousBuildState?.isFile(
            buildStepPlan: _buildPlan.buildStepPlan,
            id: id,
          ) ??
          false;
      if (!isFile) {
        // Ignore under `.dart_tool/build`.
        if (id.path.startsWith(cacheDirectoryPath)) continue;

        // Ignore modifications and deletes.
        if (change.type != ChangeType.ADD) continue;

        // It's an add: handle if it's a new input.
        if (_buildPlan.buildConfigs.anyMatchesAsset(id)) {
          result.add(change);
        }
        continue;
      }

      // Changes to files that are part of the build.

      // If not copying to a merged output directory, ignore changes to files
      // with no outputs.
      if (!_buildPlan.buildOptions.anyMergedOutputDirectory &&
          !(_buildPlan.previousBuildState?.isMissingSource(id) ?? false) &&
          _buildPlan.previousBuildState?.digestOf(
                id: id,
                buildStepPlan: _buildPlan.buildStepPlan,
              ) ==
              null) {
        continue;
      }

      // Ignore creation or modification of outputs.
      if (_buildPlan.buildStepPlan.isDeclaredOutput(id) &&
          change.type != ChangeType.REMOVE) {
        continue;
      }

      // It's an add of a "missing source" or a deletion of an input.
      result.add(change);
    }

    return result;
  }

  bool _isBuildConfiguration(AssetId id) =>
      id.path == 'build.yaml' ||
      id.path.endsWith('.build.yaml') ||
      (id.package == _buildPlan.buildPackages.outputRoot &&
          id.path == 'build.${_buildPlan.buildOptions.configKey}.yaml');

  Future<List<WatchEvent>> checkForChanges() async {
    final updates = await AssetTracker(
      _buildPlan.readerWriter,
      _buildPlan.buildPackages,
      _buildPlan.buildConfigs,
    ).collectChanges(
      buildStepPlan: _buildPlan.buildStepPlan,
      buildState: _buildPlan.previousBuildState ?? BuildState(),
    );
    return List.of(
      updates.entries.map((entry) => WatchEvent(entry.value, '${entry.key}')),
    );
  }

  /// If a build is running, the build result when it's done.
  ///
  /// If no build has ever run, returns the first build result when it's
  /// available.
  ///
  /// If a build has run, the most recent build result.
  Future<BuildResult> get currentBuildResult =>
      _currentBuildResult ?? buildResults.first;

  /// Runs a single build.
  ///
  /// For the first build, pass any changes since the `BuildSeries` was created
  /// as [updates]. If the first build happens immediately then pass empty
  /// `updates`.
  ///
  /// For further builds, pass the changes since the previous builds as
  /// [updates].
  ///
  /// Set [recentlyBootstrapped] to skip doing checks that are done during
  /// bootstrapping. If [recentlyBootstrapped] then [updates] must be empty.
  Future<BuildResult> run(
    Set<AssetId> updates, {
    required bool recentlyBootstrapped,
    BuiltSet<BuildDirectory>? buildDirs,
    BuiltSet<BuildFilter>? buildFilters,
  }) async {
    if (_closingCompleter.isCompleted) {
      throw StateError('BuildSeries was closed.');
    }

    if (recentlyBootstrapped) {
      if (updates.isNotEmpty) {
        throw StateError('`recentlyBootstrapped` but updates not empty.');
      }
    } else {
      final kernelFreshness = await _buildPlan.bootstrapper
          .checkCompileFreshness(digestsAreFresh: false);
      if (!kernelFreshness.outputIsFresh) {
        final result = BuildResult.buildScriptChanged();
        _buildResultsController.add(result);
        await close();
        return result;
      }
    }

    if (updates.any(_isBuildConfiguration)) {
      _buildPlan = await _buildPlan.reload();
      await _buildPlan.deleteFilesAndFolders();
      // A config change might have caused new builders to be needed, which
      // needs a restart to change the build script.
      if (_buildPlan.restartIsNeeded) {
        final result = BuildResult.buildScriptChanged();
        _buildResultsController.add(result);
        await close();
        return result;
      }
    }

    buildDirs ??= _buildPlan.buildOptions.buildDirs;
    buildFilters ??= _buildPlan.buildOptions.buildFilters;
    if (!firstBuild) buildLog.nextBuild();
    _buildPlan = _buildPlan.copyWith(
      buildDirs: buildDirs,
      buildFilters: buildFilters,
    );

    if (firstBuild) {
      if (updates.isNotEmpty) {
        _buildPlan = await _buildPlan.updateForFileChanges(updates);
      }
    } else {
      _buildPlan = await _buildPlan.updateForFileChanges(updates);
    }

    final build = Build(
      buildPlan: _buildPlan,
      resourceManager: _resourceManager,
    );
    if (firstBuild) firstBuild = false;

    _currentBuildResult = build.run();
    final result = await _currentBuildResult!;
    _buildPlan = build.buildPlan.updateForResult(
      previousPhasedAssetDeps: result.phasedAssetDeps,
      previousBuildState: build.buildState,
    );
    _buildResultsController.add(result);
    return result;
  }

  /// Ends the build series.
  ///
  /// First, [closing] is completed and new builds are prohibited.
  ///
  /// Then, any currently-running build is waited for, followed by cleanup of
  /// any resources via [ResourceManager.beforeExit].
  ///
  /// Finally, [buildResults] is closed.
  Future<void> close() async {
    if (_closingCompleter.isCompleted) return;
    _closingCompleter.complete();
    await _currentBuildResult;
    await _resourceManager.beforeExit();

    // Close the results stream last: this indicates that cleanup is done.
    await _buildResultsController.close();
  }
}
