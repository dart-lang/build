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
import '../build_plan/output_strategy.dart';
import '../commands/watch/asset_change.dart';
import '../constants.dart';
import '../io/asset_tracker.dart';
import '../io/create_merged_dir.dart';
import '../logging/build_log.dart';
import 'asset_content.dart';
import 'build.dart';
import 'build_result.dart';
import 'build_state/asset_graph_json.dart';
import 'build_state/build_state.dart';
import 'resolver/asset_ids.dart';

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

  /// Deletes that are part of build output, so the resulting file watch events
  /// can be ignored.
  final Set<AssetId> _expectedDeletes = {};

  /// Writes that are part of build output, so the resulting file watch events
  /// can be ignored.
  final Set<AssetId> _expectedWrites = {};

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
  Future<List<AssetChange>> filterChanges(List<AssetChange> changes) async {
    final result = <AssetChange>[];
    for (final change in changes) {
      final id = change.id;

      // Changes to the entrypoint are handled via depfiles.
      if (_buildPlan.buildSpec.bootstrapper.isCompileDependency(
        _buildPlan.buildSpec.buildPackages.pathFor(id, hide: false),
      )) {
        result.add(change);
        continue;
      }

      // Ignore any expected delete once.
      if (change.type == ChangeType.REMOVE && _expectedDeletes.remove(id)) {
        continue;
      }

      // Ignore any expected write once.
      if ((change.type == ChangeType.ADD || change.type == ChangeType.MODIFY) &&
          _expectedWrites.remove(id)) {
        continue;
      }

      if (id.path.startsWith(entrypointDirectoryPath)) {
        continue;
      }

      if (_isBuildConfiguration(id)) {
        result.add(change);
        continue;
      }

      final isFile =
          _buildPlan.previousBuild.buildState?.isFile(
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
        if (_buildPlan.buildSpec.buildConfigs.anyMatchesAsset(id)) {
          result.add(change);
        }
        continue;
      }

      // Changes to files that are part of the build.

      // If not copying to a merged output directory, ignore changes to files
      // with no outputs.
      if (!_buildPlan.buildSpec.buildOptions.anyMergedOutputDirectory &&
          !(_buildPlan.previousBuild.buildState?.isMissingSource(id) ??
              false) &&
          _buildPlan.previousBuild.buildState?.contentOf(
                id: id,
                buildStepPlan: _buildPlan.buildStepPlan,
              ) ==
              null) {
        continue;
      }

      // Handle modifications and creations of outputs.
      if (_buildPlan.buildStepPlan.isDeclaredOutput(id) &&
          change.type != ChangeType.REMOVE) {
        if (_buildPlan.buildSpec.buildOptions.outputStrategy ==
            OutputStrategy.keep) {
          continue;
        }
      }

      // It's an add of a "missing source" or a deletion of an input.
      result.add(change);
    }

    return result;
  }

  bool _isBuildConfiguration(AssetId id) =>
      id.path == 'build.yaml' ||
      id.path.endsWith('.build.yaml') ||
      (id.package == _buildPlan.buildSpec.buildPackages.outputRoot &&
          id.path ==
              'build.${_buildPlan.buildSpec.buildOptions.configKey}.yaml');

  Future<List<WatchEvent>> checkForChanges() async {
    final updates =
        await AssetTracker(
          _buildPlan.readerWriter,
          _buildPlan.buildSpec.buildPackages,
          _buildPlan.buildSpec.buildConfigs,
        ).collectChanges(
          buildStepPlan: _buildPlan.buildStepPlan,
          buildState: _buildPlan.previousBuild.buildState ?? BuildState(),
        );

    if (_buildPlan.buildSpec.buildOptions.outputStrategy ==
        OutputStrategy.keep) {
      final declaredOutputs = _buildPlan.buildStepPlan.declaredOutputs;
      updates.removeWhere(
        (id, type) => type != ChangeType.REMOVE && declaredOutputs.contains(id),
      );
    }

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
      final kernelFreshness = await _buildPlan.buildSpec.bootstrapper
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
      // A config change might have caused new builders to be needed, which
      // needs a restart to change the build script.
      if (_buildPlan.buildSpec.restartIsNeeded) {
        final result = BuildResult.buildScriptChanged();
        _buildResultsController.add(result);
        await close();
        return result;
      }
    }

    buildDirs ??= _buildPlan.buildDirs;
    buildFilters ??= _buildPlan.buildFilters;
    if (!firstBuild) buildLog.nextBuild();
    _buildPlan = _buildPlan.rebuild(
      (b) => b
        ..buildDirs.replace(buildDirs!)
        ..buildFilters.replace(buildFilters!),
    );

    if (firstBuild) {
      if (updates.isNotEmpty) {
        if (_buildPlan.buildSpec.buildOptions.outputStrategy ==
            OutputStrategy.keep) {
          final declaredOutputs = _buildPlan.buildStepPlan.declaredOutputs;
          updates = updates
              .where((id) => !declaredOutputs.contains(id))
              .toSet();
        }
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

    _currentBuildResult = _runBuildAndWrite(build);
    final result = await _currentBuildResult!;
    _buildResultsController.add(result);
    return result;
  }

  Future<BuildResult> _runBuildAndWrite(Build build) async {
    var result = await build.run();

    if (_buildPlan.buildSpec.buildOptions.outputStrategy ==
        OutputStrategy.verify) {
      if (result.status == BuildStatus.success) {
        result = await _verifyBuildOutput(result);
      }
    } else {
      await _writeBuildOutput(result);
    }
    result = await _createMergedOutputDirectories(result);

    _buildPlan = build.buildPlan.withCompatiblePreviousBuild(
      previousPhasedAssetDeps: result.phasedAssetDeps,
      previousBuildState: build.buildState,
    );
    return result.copyWith(
      errors: buildLog.finishBuild(
        result: result.status == BuildStatus.success,
        outputs: result.outputs.length,
      ),
    );
  }

  /// Deletes old build output, writes new build output.
  ///
  /// Serializes and writes the updated `asset_graph.json`.
  Future<void> _writeBuildOutput(BuildResult result) async {
    final deletes = _computeDeletes(result);

    if (_buildPlan.buildInputs.cleanBuild) {
      final generatedOutputDirectoryId = AssetId(
        _buildPlan.buildSpec.buildPackages.outputRoot,
        generatedOutputDirectory,
      );
      await _buildPlan.readerWriter.deleteDirectory(generatedOutputDirectoryId);
    }

    for (final output in result.outputs) {
      deletes.remove(output);
      final content = result.buildState!.contentOf(
        id: output,
        buildStepPlan: _buildPlan.buildStepPlan,
      )!;
      _expectedWrites.add(output);
      await _buildPlan.readerWriter.writeAsBytes(
        output,
        content.bytes,
        hidden: output.isHidden(
          buildStepPlan: _buildPlan.buildStepPlan,
          buildState: result.buildState!,
        ),
      );
    }
    for (final entry in deletes.entries) {
      await _buildPlan.readerWriter.delete(
        entry.key,
        hidden: entry.value,
        onDelete: _expectedDeletes.add,
      );
    }

    final assetGraphId = AssetId(
      _buildPlan.buildSpec.buildPackages.outputRoot,
      assetGraphJsonPath,
    );
    _expectedWrites.add(assetGraphId);
    final assetGraphContent = AssetContent.bytes(
      AssetGraphJson.serialize(
        buildPlanDigest: _buildPlan.buildSpec.buildPlanDigest,
        buildState: result.buildState!,
        phasedAssetDeps: result.phasedAssetDeps,
      ),
    );
    await _buildPlan.readerWriter.writeAsBytes(
      assetGraphId,
      assetGraphContent.bytes,
    );
  }

  /// Outputs to delete and whether each is hidden.
  Map<AssetId, bool> _computeDeletes(BuildResult result) {
    final deletes = <AssetId, bool>{
      for (final id in _buildPlan.conflictingOutputs) id: false,
      for (final id
          in _buildPlan.previousBuild.incompatibleBuildOutputsToDelete)
        id: false,
    };

    final previousState = _buildPlan.previousBuild.buildState;
    if (previousState != null) {
      final currentState = result.buildState!;
      for (final stepResult in previousState.actualStepResults) {
        for (final id in stepResult.outputs.keys) {
          final stepId = _buildPlan.buildStepPlan.stepForDeclaredOutputOrNull(
            id,
          );
          if (stepId == null) {
            deletes[id] = stepResult.isHidden;
          } else {
            final stepResultOrNull = currentState.stepResultOrNull(stepId);
            if (stepResultOrNull != null &&
                !stepResultOrNull.outputs.containsKey(id)) {
              deletes[id] = stepResult.isHidden;
            }
          }
        }
      }
      for (final postProcessResult in previousState.actualPostProcessResults) {
        for (final id in postProcessResult.outputs.keys) {
          if (!currentState.isActualPostOutput(id)) {
            deletes[id] = postProcessResult.hidden;
          }
        }
      }
    }
    return deletes;
  }

  Future<BuildResult> _verifyBuildOutput(BuildResult result) async {
    final deletes = _computeDeletes(result);
    final deletesToCheck = deletes.keys.where((id) => !deletes[id]!).toSet();

    final unexpected = <AssetId>[];
    final missing = <AssetId>[];
    final incorrect = <AssetId>[];

    for (final output in result.outputs) {
      deletesToCheck.remove(output);
      final hidden = output.isHidden(
        buildStepPlan: _buildPlan.buildStepPlan,
        buildState: result.buildState!,
      );
      if (hidden) continue;

      final expectedContent = result.buildState!.contentOf(
        id: output,
        buildStepPlan: _buildPlan.buildStepPlan,
      )!;
      final exists = await _buildPlan.readerWriter.canRead(output);
      if (!exists) {
        missing.add(output);
      } else {
        final existingBytes = await _buildPlan.readerWriter.readAsBytes(output);
        final existingDigest = AssetContent.bytes(existingBytes).digest;
        if (existingDigest != expectedContent.digest) {
          incorrect.add(output);
        }
      }
    }

    for (final toDelete in deletesToCheck) {
      final exists = await _buildPlan.readerWriter.canRead(toDelete);
      if (exists) {
        unexpected.add(toDelete);
      }
    }

    if (unexpected.isNotEmpty || missing.isNotEmpty || incorrect.isNotEmpty) {
      final lines = <String>[
        for (final id in unexpected) 'U ${buildLog.renderId(id)}',
        for (final id in missing) 'M ${buildLog.renderId(id)}',
        for (final id in incorrect) 'I ${buildLog.renderId(id)}',
      ]..sort();

      final message = StringBuffer(
        'Verify failed due to Unexpected|Incorrect|Missing:\n\n',
      );
      message.write(lines.join('\n'));
      buildLog.error(message.toString());

      return result.copyWith(status: BuildStatus.failure);
    }
    return result;
  }

  /// Creates merged output directories if they are configured.
  ///
  /// Returns `result` with `status` modified to `failure` if any creation
  /// failed.
  Future<BuildResult> _createMergedOutputDirectories(BuildResult result) async {
    if (_buildPlan.buildDirs.any(
          (target) => target.outputLocation?.path.isNotEmpty ?? false,
        ) &&
        result.status == BuildStatus.success) {
      if (!await createMergedOutputDirectories(
        buildPackages: _buildPlan.buildSpec.buildPackages,
        outputSymlinksOnly:
            _buildPlan.buildSpec.buildOptions.outputSymlinksOnly,
        buildDirs: _buildPlan.buildDirs,
        buildOutputReader: result.buildOutputReader!,
      )) {
        return result.copyWith(
          status: BuildStatus.failure,
          failureType: FailureType.cantCreate,
        );
      }
    }
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
