// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart';
import 'package:built_collection/built_collection.dart';
import 'package:crypto/crypto.dart';
import 'package:watcher/watcher.dart';

import '../build_file.dart';
import '../build_plan/build_directory.dart';
import '../build_plan/build_filter.dart';
import '../build_plan/build_plan.dart';
import '../build_plan/output_strategy.dart';
import '../commands/watch/build_file_change.dart';
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
  final Set<AssetFile> _expectedDeletes = {};

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

  OutputStrategy get _outputStrategy =>
      _buildPlan.buildSpec.buildOptions.outputStrategy;

  /// Filters [changes] to only changes that might trigger a build.
  Future<List<BuildFileChange>> filterChanges(
    List<BuildFileChange> changes,
  ) async {
    final result = <BuildFileChange>[];
    final buildPackages = _buildPlan.buildSpec.buildPackages;
    for (final change in changes) {
      final diskPath = buildPackages.pathFor(change.file);

      // Changes to the entrypoint are handled via depfiles.
      if (_buildPlan.buildSpec.bootstrapper.isCompileDependency(change.path) ||
          _buildPlan.buildSpec.bootstrapper.isCompileDependency(diskPath)) {
        result.add(change);
        continue;
      }

      final assetFile = change.assetFile;
      if (assetFile == null) continue;
      final id = assetFile.id;

      // Ignore deletes and writes done by `build_runner`, for output strategies
      // that do deletes and writes.
      if (_outputStrategy == OutputStrategy.overwrite ||
          _outputStrategy == OutputStrategy.keep) {
        // Ignore deletes done by `build_runner`.
        if (change.type == ChangeType.REMOVE &&
            _expectedDeletes.remove(assetFile)) {
          continue;
        }

        // Ignore writes done by `build_runner`. It's necessary to check content
        // because `package:watcher` can coalesce two modify events into one.
        // If the first is by `build_runner` and the second is an external
        // change then just ignoring the event would be incorrect.
        if ((change.type == ChangeType.ADD ||
                change.type == ChangeType.MODIFY) &&
            _buildPlan.buildStepPlan.isDeclaredOutput(id)) {
          final expectedContent = _buildPlan.previousBuild.buildState
              ?.contentOf(id: id, buildStepPlan: _buildPlan.buildStepPlan);
          if (expectedContent != null) {
            try {
              final bytes = await _buildPlan.readerWriter.readFileAsBytes(
                assetFile,
              );
              if (md5.convert(bytes) == expectedContent.digest) {
                continue;
              }
            } catch (_) {}
          }
        }
      }

      if (id.path.startsWith(entrypointDirectoryPath)) {
        continue;
      }

      if (_isBuildConfiguration(assetFile)) {
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
          change.type != ChangeType.REMOVE &&
          _outputStrategy == OutputStrategy.keep) {
        continue;
      }

      // It's an add of a "missing source" or a deletion of an input.
      result.add(change);
    }

    return result;
  }

  bool _isBuildConfiguration(BuildFile file) =>
      file.path == 'build.yaml' ||
      file.path.endsWith('.build.yaml') ||
      (file.package == _buildPlan.buildSpec.buildPackages.outputRoot &&
          file.path ==
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

    final buildPackages = _buildPlan.buildSpec.buildPackages;
    return List.of(
      updates.entries.map(
        (entry) => WatchEvent(
          entry.value,
          buildPackages.pathFor(AssetFile.source(entry.key)),
        ),
      ),
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
    Set<AssetFile> updates, {
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

    if (!firstBuild || updates.isNotEmpty) {
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

    if (_outputStrategy == .verify) {
      if (result.status == .success) {
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
        result: result.status == .success,
        outputs: result.outputs.length,
      ),
    );
  }

  /// Deletes old build output, writes new build output.
  ///
  /// Serializes and writes the updated `asset_graph.json`.
  Future<void> _writeBuildOutput(BuildResult result) async {
    if (_buildPlan.buildInputs.cleanBuild) {
      await _buildPlan.readerWriter.deleteDirectoryFile(
        InternalFile(
          _buildPlan.buildSpec.buildPackages.outputRoot,
          generatedOutputDirectory,
        ),
      );
    }

    for (final output in result.outputs) {
      final content = result.buildState!.contentOf(
        id: output,
        buildStepPlan: _buildPlan.buildStepPlan,
      )!;
      await _buildPlan.readerWriter.writeAsBytes(
        output,
        content.bytes,
        hidden: output.isHidden(
          buildStepPlan: _buildPlan.buildStepPlan,
          buildState: result.buildState!,
        ),
      );
    }
    for (final toDelete in _computeDeletes(result)) {
      _expectedDeletes.add(toDelete);
      await _buildPlan.readerWriter.deleteFile(toDelete);
    }

    final assetGraphContent = AssetContent.bytes(
      AssetGraphJson.serialize(
        buildPlanDigest: _buildPlan.buildSpec.buildPlanDigest,
        buildState: result.buildState!,
        phasedAssetDeps: result.phasedAssetDeps,
      ),
    );
    await _buildPlan.readerWriter.writeFileAsBytes(
      InternalFile(
        _buildPlan.buildSpec.buildPackages.outputRoot,
        assetGraphJsonPath,
      ),
      assetGraphContent.bytes,
    );
  }

  /// Files that should be deleted: outputs of the previous build that are no
  /// longer declared outputs, plus files on disk that match declared outputs
  /// that were not actually output.
  ///
  /// Set [onlyVisible] to skip hidden files.
  Set<AssetFile> _computeDeletes(
    BuildResult result, {
    bool onlyVisible = false,
  }) {
    final deletes = <AssetFile>{};
    final currentState = result.buildState!;
    for (final id in _buildPlan.conflictingOutputs) {
      if (!currentState.isActualOutput(
            id: id,
            buildStepPlan: _buildPlan.buildStepPlan,
          ) &&
          !currentState.isActualPostOutput(id)) {
        deletes.add(AssetFile.source(id));
      }
    }
    for (final id
        in _buildPlan.previousBuild.incompatibleBuildOutputsToDelete) {
      if (!currentState.isActualOutput(
            id: id,
            buildStepPlan: _buildPlan.buildStepPlan,
          ) &&
          !currentState.isActualPostOutput(id)) {
        deletes.add(AssetFile.source(id));
      }
    }

    // Adds a delete result, unless it's a hidden file and `onlyVisible` was
    // requested.
    void maybeAddDelete(AssetId id, bool isHidden) {
      if (isHidden) {
        if (!onlyVisible) {
          deletes.add(AssetFile.cache(id));
        }
      } else {
        deletes.add(AssetFile.source(id));
      }
    }

    final previousState = _buildPlan.previousBuild.buildState;
    if (previousState != null) {
      for (final stepResult in previousState.actualStepResults) {
        for (final id in stepResult.outputs.keys) {
          final stepId = _buildPlan.buildStepPlan.stepForDeclaredOutputOrNull(
            id,
          );
          if (stepId == null) {
            maybeAddDelete(id, stepResult.isHidden);
          } else {
            final stepResultOrNull = currentState.stepResultOrNull(stepId);
            if (stepResultOrNull != null &&
                !stepResultOrNull.outputs.containsKey(id)) {
              maybeAddDelete(id, stepResult.isHidden);
            }
          }
        }
      }
      for (final postProcessResult in previousState.actualPostProcessResults) {
        for (final id in postProcessResult.outputs.keys) {
          if (!currentState.isActualPostOutput(id)) {
            maybeAddDelete(id, postProcessResult.hidden);
          }
        }
      }
    }
    return deletes;
  }

  /// Verifies outputs on disk match [result].
  ///
  /// If there are unexpected, missing, or incorrect outputs on disk, logs them
  /// and returns a failed result.
  ///
  /// Only outputs and deletes in the source tree are checked; hidden outputs
  /// and deletes of hidden files are skipped. This supports the presubmit use
  /// case where source tree generated files are checked in but `.dart_tool`
  /// generated files are not.
  Future<BuildResult> _verifyBuildOutput(BuildResult result) async {
    final unexpected = <AssetId>[];
    final missing = <AssetId>[];
    final incorrect = <AssetId>[];

    for (final output in result.outputs) {
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

    for (final toDelete in _computeDeletes(result, onlyVisible: true)) {
      final exists = await _buildPlan.readerWriter.canRead(toDelete.id);
      if (exists) {
        unexpected.add(toDelete.id);
      }
    }

    if (unexpected.isNotEmpty || missing.isNotEmpty || incorrect.isNotEmpty) {
      final lines = <String>[
        for (final id in unexpected) 'U ${buildLog.renderId(id)}',
        for (final id in missing) 'M ${buildLog.renderId(id)}',
        for (final id in incorrect) 'I ${buildLog.renderId(id)}',
      ]..sort();

      final message = StringBuffer(
        'Verify failed due to Incorrect|Missing|Unexpected:\n\n',
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
