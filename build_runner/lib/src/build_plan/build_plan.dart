// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:build/build.dart' hide Builder;
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:crypto/crypto.dart';
import 'package:watcher/watcher.dart';

import '../build/build_state/asset_graph_json.dart';
import '../build/build_state/build_state.dart';
import '../build/library_cycle_graph/phased_asset_deps.dart';
import '../constants.dart';
import '../exceptions.dart';
import '../io/asset_tracker.dart';
import '../io/generated_asset_hider.dart';
import '../io/reader_writer.dart';
import '../logging/build_log.dart';
import 'build_directory.dart';
import 'build_filter.dart';
import 'build_inputs.dart';
import 'build_spec.dart';
import 'build_spec_digest.dart';
import 'build_step_plan.dart';

part 'build_plan.g.dart';

/// Options and derived configuration for a build.
abstract class BuildPlan implements Built<BuildPlan, BuildPlanBuilder> {
  BuildSpec get buildSpec;

  /// Per-build build dirs, which can differ from the global option in
  /// `BuildOptions`.
  BuiltSet<BuildDirectory> get buildDirs;

  /// Per-build build filters, which can differ from the global option in
  /// `BuildOptions`.
  BuiltSet<BuildFilter> get buildFilters;

  ReaderWriter get readerWriter;

  BuildState? get previousBuildState;
  PhasedAssetDeps? get previousPhasedAssetDeps;
  BuildStepPlan get buildStepPlan;

  /// Whether build triggers config changed since the previous build.
  bool get triggersChanged;

  /// Whether phase options per phase changed since the previous build.
  BuiltList<bool> get phaseOptionsChangedList;

  /// Whether post process phase options per phase changed since the previous
  /// build.
  BuiltList<bool> get postBuildOptionsChangedList;

  /// Files to delete before restarting or before the next build.
  ///
  /// - Outputs from the previous build.
  /// - Files on disk that conflict with outputs of the current build.
  /// - The build state, if it's invalid.
  ///
  /// Call [deleteFilesAndFolders] to delete them.
  BuiltList<AssetId> get filesToDelete;

  /// Folders to delete before restarting or before the next build.
  ///
  /// Call [deleteFilesAndFolders] to delete them.
  BuiltList<AssetId> get foldersToDelete;

  /// Sources and changes to sources before the build.
  BuildInputs get buildInputs;

  BuildPlan._();
  factory BuildPlan([void Function(BuildPlanBuilder) updates]) = _$BuildPlan;

  /// Loads the build plan for [buildSpec].
  ///
  /// Deserializes and checks the `BuildState`. If it's compatible, it's
  /// available as [previousBuildState]. If not, it's discarded.
  ///
  /// Files that should be deleted before restarting or building are accumulated
  /// in [filesToDelete] and [foldersToDelete]. Call [deleteFilesAndFolders] to
  /// delete them.
  ///
  /// [buildInputs] are resolved.
  static Future<BuildPlan> load(BuildSpec buildSpec) async {
    final readerWriter = buildSpec.readerWriter;
    final buildPackages = buildSpec.buildPackages;
    final buildPlanDigest = buildSpec.buildPlanDigest;

    final assetGraphJsonId = AssetId(
      buildPackages.outputRoot,
      assetGraphJsonPath,
    );
    final generatedOutputDirectoryId = AssetId(
      buildPackages.outputRoot,
      generatedOutputDirectory,
    );
    BuildSpecDigest? previousBuildPlanDigest;
    BuildState? previousBuildState;
    final filesToDelete = <AssetId>{};
    final foldersToDelete = <AssetId>{};

    PhasedAssetDeps? previousPhasedAssetDeps;
    if (await readerWriter.canRead(assetGraphJsonId)) {
      final assetGraphJson = AssetGraphJson.deserialize(
        await readerWriter.readAsBytes(assetGraphJsonId) as Uint8List,
      );
      if (assetGraphJson != null) {
        previousBuildState = assetGraphJson.buildState;
        previousBuildPlanDigest = assetGraphJson.buildPlanDigest;
        previousPhasedAssetDeps = assetGraphJson.phasedAssetDeps;
      }
      if (previousBuildState != null) {
        if (buildSpec.restartIsNeeded ||
            !buildPlanDigest.canIncrementallyBuildFrom(
              previousBuildPlanDigest,
            )) {
          // Mark old outputs for deletion.
          filesToDelete.addAll(
            previousBuildState.outputsToDelete(buildPackages),
          );

          // Discard the invalid build state so that a new one will be created
          // from scratch.
          previousBuildState = null;
        }
      }
    }

    // If there was no previous build state or it was invalid, start by deleting
    // any invalid asset graph json file and the generated output directory.
    if (previousBuildState == null) {
      filesToDelete.add(assetGraphJsonId);
      foldersToDelete.add(generatedOutputDirectoryId);
    }

    final assetTracker = AssetTracker(
      readerWriter,
      buildPackages,
      buildSpec.buildConfigs,
    );
    final inputSources = await assetTracker.findInputSources();
    final cacheDirSources = await assetTracker.findCacheDirSources();

    Set<AssetId>? updates;
    if (previousBuildState != null) {
      updates = {
        ...inputSources,
        ...cacheDirSources,
        ...previousBuildState.sources,
        ...previousBuildState.actualOutputs,
      };

      if (buildSpec.restartIsNeeded) {
        // Mark old outputs for deletion.
        filesToDelete.addAll(previousBuildState.outputsToDelete(buildPackages));
        foldersToDelete.add(generatedOutputDirectoryId);

        // Discard the invalid AssetGraphJson so that a new one will be created
        // from scratch, and mark it for deletion so that the same will happen
        // if restarting.
        previousBuildState = null;
        filesToDelete.add(assetGraphJsonId);

        // Discard state tied to the invalid AssetGraphJson.
        updates = null;
      }
    }

    Set<AssetId> sourcesForBuildStepPlan;
    if (previousBuildState == null) {
      // Files marked for deletion are not inputs.
      inputSources.removeAll(filesToDelete);

      // Compute build steps just to get declared outputs and prune the input
      // sources to remove them. They are computed again below based on the
      // pruned inputs.
      final declaredOutputs = BuildStepPlan.compute(
        buildPhases: buildSpec.buildPhases,
        placeholderIds: buildPackages.placeholderIds,
        sources: inputSources,
      ).declaredOutputs;
      final inputSourcesWithoutOutputs = Set<AssetId>.from(inputSources);
      for (final output in declaredOutputs) {
        inputSourcesWithoutOutputs.remove(output);
      }

      sourcesForBuildStepPlan = inputSourcesWithoutOutputs;
      updates = inputSourcesWithoutOutputs;
    } else {
      sourcesForBuildStepPlan = previousBuildState.sources.toSet();
    }

    final buildStepPlan = BuildStepPlan.compute(
      buildPhases: buildSpec.buildPhases,
      placeholderIds: buildPackages.placeholderIds,
      sources: sourcesForBuildStepPlan,
    );
    final declaredAndActualOutputs = [
      ...buildStepPlan.declaredOutputs,
      if (previousBuildState != null) ...previousBuildState.actualPostOutputs,
    ];

    if (previousBuildState == null) {
      final conflictsInDeps = declaredAndActualOutputs
          .where((n) => !buildPackages.outputPackages.contains(n.package))
          .where(inputSources.contains)
          .toSet();
      if (conflictsInDeps.isNotEmpty) {
        buildLog.error(
          'There are existing files in dependencies which conflict '
          'with files that a Builder may produce. These must be removed or '
          'the Builders disabled before a build can continue: '
          '${conflictsInDeps.map((a) => a.uri).join('\n')}',
        );
        throw const CannotBuildException();
      }

      filesToDelete.addAll(
        declaredAndActualOutputs
            .where((n) => buildPackages.outputPackages.contains(n.package))
            .where(inputSources.contains)
            .toSet(),
      );
    }

    final finalReaderWriter = readerWriter.copyWith(
      generatedAssetHider: buildSpec.testingOverrides.flattenOutput
          ? const NoopGeneratedAssetHider()
          : buildStepPlan,
    );

    return _createAndResolve(
      buildSpec: buildSpec,
      buildDirs: buildSpec.buildOptions.buildDirs,
      buildFilters: buildSpec.buildOptions.buildFilters,
      readerWriter: finalReaderWriter,
      buildStepPlan: buildStepPlan,
      previousBuildState: previousBuildState,
      previousPhasedAssetDeps: previousPhasedAssetDeps,
      filesToDelete: filesToDelete.toBuiltList(),
      foldersToDelete: foldersToDelete.toBuiltList(),
      triggersChanged: !buildPlanDigest.hasSameTriggersAs(
        previousBuildPlanDigest,
      ),
      phaseOptionsChanged: buildPlanDigest.computeChangedPhaseOptions(
        previousBuildPlanDigest,
      ),
      postBuildOptionsChanged: buildPlanDigest.computeChangedPostBuildOptions(
        previousBuildPlanDigest,
      ),
      updates: updates ?? {},
    );
  }

  /// Returns a copy of the plan updated for the next incremental build.
  ///
  /// Updates [previousPhasedAssetDeps] from the build result.
  ///
  /// Sets [triggersChanged], `phaseOptionsChanged` and
  /// `postBuildOptionsChanged` to `false`.
  BuildPlan updateForResult({
    PhasedAssetDeps? previousPhasedAssetDeps,
    BuildState? previousBuildState,
  }) => rebuild((b) {
    b.triggersChanged = false;
    if (previousPhasedAssetDeps == null) {
      b.previousPhasedAssetDeps = null;
    } else {
      b.previousPhasedAssetDeps.replace(previousPhasedAssetDeps);
    }
    b.previousBuildState = previousBuildState;
    b.phaseOptionsChangedList.replace(
      BuiltList<bool>.from(
        List.filled(
          buildStepPlan.buildPhases.inBuildPhasesOptionsDigests.length,
          false,
        ),
      ),
    );
    b.postBuildOptionsChangedList.replace(
      BuiltList<bool>.from(
        List.filled(
          buildStepPlan.buildPhases.postBuildActionsOptionsDigests.length,
          false,
        ),
      ),
    );
  });

  Future<BuildPlan> updateForFileChanges(Set<AssetId> updates) {
    return _createAndResolve(
      buildSpec: buildSpec,
      buildDirs: buildDirs,
      buildFilters: buildFilters,
      readerWriter: readerWriter,
      buildStepPlan: buildStepPlan,
      previousBuildState: previousBuildState,
      previousPhasedAssetDeps: previousPhasedAssetDeps,
      filesToDelete: filesToDelete,
      foldersToDelete: foldersToDelete,
      triggersChanged: triggersChanged,
      phaseOptionsChanged: phaseOptionsChangedList,
      postBuildOptionsChanged: postBuildOptionsChangedList,
      updates: updates,
    );
  }

  /// Whether [phaseNumber] has different options to the previous build
  /// and must be fully rebuilt.
  bool phaseOptionsChanged(int phaseNumber) =>
      phaseOptionsChangedList[phaseNumber];

  /// Whether [actionNumber] has different options to the previous build
  /// and must be fully rebuilt.
  bool postBuildOptionsChanged(int actionNumber) =>
      postBuildOptionsChangedList[actionNumber];

  Future<void> deleteFilesAndFolders() async {
    // Hidden outputs are deleted if needed by deleting the entire folder. So,
    // only outputs in the source folder need to be deleted explicitly. Use a
    // `ReaderWriter` that only acts on the source folder.
    final cleanupReaderWriter = readerWriter.copyWith(
      generatedAssetHider: const NoopGeneratedAssetHider(),
    );
    for (final id in filesToDelete) {
      if (await cleanupReaderWriter.canRead(id)) {
        await cleanupReaderWriter.delete(id);
      }
    }
    for (final id in foldersToDelete) {
      await cleanupReaderWriter.deleteDirectory(id);
    }
  }

  static Future<BuildPlan> _createAndResolve({
    required BuildSpec buildSpec,
    required BuiltSet<BuildDirectory> buildDirs,
    required BuiltSet<BuildFilter> buildFilters,
    required ReaderWriter readerWriter,
    required BuildStepPlan buildStepPlan,
    required BuildState? previousBuildState,
    required PhasedAssetDeps? previousPhasedAssetDeps,
    required BuiltList<AssetId> filesToDelete,
    required BuiltList<AssetId> foldersToDelete,
    required bool triggersChanged,
    required BuiltList<bool> phaseOptionsChanged,
    required BuiltList<bool> postBuildOptionsChanged,
    required Set<AssetId> updates,
  }) async {
    final result = BuildInputsBuilder();

    final newDigests = <AssetId, Digest>{};
    final resolvedUpdates = <AssetId, ChangeType>{};
    final previousSources = <AssetId>{};

    final isCleanBuild = previousBuildState == null;
    result.cleanBuild = isCleanBuild;

    if (isCleanBuild) {
      for (final id in updates) {
        if (await readerWriter.canRead(id)) {
          result.sources.add(id);
        }
      }

      final newBuildStepPlan = BuildStepPlan.compute(
        buildPhases: buildStepPlan.buildPhases,
        placeholderIds: buildSpec.buildPackages.placeholderIds,
        sources: result.sources.build(),
      );
      for (final id in result.sources.build()) {
        if (newBuildStepPlan.declaredOutputsOf(id).isNotEmpty) {
          try {
            result.digests[id] = await readerWriter.digest(id);
          } catch (_) {}
        }
      }
      final newReaderWriter = readerWriter.copyWith(
        generatedAssetHider: buildSpec.testingOverrides.flattenOutput
            ? const NoopGeneratedAssetHider()
            : newBuildStepPlan,
      );
      return BuildPlan((b) {
        b.buildSpec.replace(buildSpec);
        b.buildDirs.replace(buildDirs);
        b.buildFilters.replace(buildFilters);
        b.readerWriter = newReaderWriter;
        b.buildStepPlan.replace(newBuildStepPlan);
        b.previousBuildState = previousBuildState;
        b.previousPhasedAssetDeps = previousPhasedAssetDeps?.toBuilder();
        b.filesToDelete.replace(filesToDelete);
        b.foldersToDelete.replace(foldersToDelete);
        b.triggersChanged = triggersChanged;
        b.phaseOptionsChangedList.replace(phaseOptionsChanged);
        b.postBuildOptionsChangedList.replace(postBuildOptionsChanged);
        b.buildInputs.replace(result.build());
      });
    }

    readerWriter.cache.invalidate(updates);

    for (final id in updates) {
      final oldIsSource = previousBuildState.isSource(id);
      if (oldIsSource) {
        previousSources.add(id);
      }
      final oldExisted = previousBuildState.isFile(
        buildStepPlan: buildStepPlan,
        id: id,
      );
      final oldDigest = oldIsSource
          ? previousBuildState.digestOfSource(id)
          : null;
      var exists = false;
      Digest? newDigest;

      if (await readerWriter.canRead(id)) {
        exists = true;
        if (oldDigest != null) {
          try {
            newDigest = await readerWriter.digest(id);
            newDigests[id] = newDigest;
          } catch (_) {
            exists = false;
          }
        }
      }

      if (oldExisted && !exists) {
        resolvedUpdates[id] = ChangeType.REMOVE;
        if (oldIsSource) {
          result.deletedSources.add(id);
        } else {
          result.deletedOutputs.add(id);
        }
      } else if (!oldExisted && exists) {
        result.addedSources.add(id);
        resolvedUpdates[id] = ChangeType.ADD;
      } else if (oldExisted &&
          oldDigest != null &&
          exists &&
          oldDigest != newDigest) {
        result.modifiedSources.add(id);
        resolvedUpdates[id] = ChangeType.MODIFY;
      }
    }

    result.sources.addAll(previousBuildState.sources);
    for (final entry in resolvedUpdates.entries) {
      final id = entry.key;
      switch (entry.value) {
        case ChangeType.ADD:
        case ChangeType.MODIFY:
          if (!previousBuildState.isSource(id) ||
              previousBuildState.isMissingSource(id)) {
            result.sources.add(id);
          }
        case ChangeType.REMOVE:
          if (previousBuildState.isSource(id)) {
            result.sources.remove(id);
          }
      }
    }

    for (final id in result.sources.build()) {
      if (resolvedUpdates[id] == null) {
        if (previousBuildState.isSource(id)) {
          final digest = previousBuildState.digestOfSource(id);
          if (digest != null) {
            result.digests[id] = digest;
          }
        }
      } else if (newDigests[id] != null) {
        result.digests[id] = newDigests[id]!;
      }
    }

    final newBuildStepPlan = BuildStepPlan.compute(
      buildPhases: buildStepPlan.buildPhases,
      placeholderIds: buildSpec.buildPackages.placeholderIds,
      sources: result.sources.build(),
    );

    for (final id in result.sources.build()) {
      if (result.digests[id] == null &&
          newBuildStepPlan.declaredOutputsOf(id).isNotEmpty) {
        try {
          result.digests[id] = await readerWriter.digest(id);
        } catch (_) {}
      }
    }

    final deletedOutputs = buildStepPlan
        .transitiveDeclaredOutputsOf(result.deletedSources.build())
        .toSet();
    result.deletedOutputs.addAll(deletedOutputs);

    final generatedReaderWriter = readerWriter.copyWith(
      generatedAssetHider: buildSpec.testingOverrides.flattenOutput
          ? const NoopGeneratedAssetHider()
          : newBuildStepPlan,
    );
    for (final id in deletedOutputs) {
      await generatedReaderWriter.delete(id);
    }

    return BuildPlan((b) {
      b.buildSpec.replace(buildSpec);
      b.buildDirs.replace(buildDirs);
      b.buildFilters.replace(buildFilters);
      b.readerWriter = generatedReaderWriter;
      b.buildStepPlan.replace(newBuildStepPlan);
      b.previousBuildState = previousBuildState;
      if (previousPhasedAssetDeps == null) {
        b.previousPhasedAssetDeps = null;
      } else {
        b.previousPhasedAssetDeps.replace(previousPhasedAssetDeps);
      }
      b.filesToDelete.replace(filesToDelete);
      b.foldersToDelete.replace(foldersToDelete);
      b.triggersChanged = triggersChanged;
      b.phaseOptionsChangedList.replace(phaseOptionsChanged);
      b.postBuildOptionsChangedList.replace(postBuildOptionsChanged);
      b.buildInputs.replace(result.build());
    });
  }

  /// Reloads the build plan.
  ///
  /// Works just like a new load of the build plan, but sets
  /// `recentlyBootstrapped` to `false` to redo checks from bootstrapping.
  ///
  /// The caller must call [deleteFilesAndFolders] on the result and check
  /// `buildSpec.restartIsNeeded`.
  Future<BuildPlan> reload() async => BuildPlan.load(
    await BuildSpec.load(
      builderFactories: buildSpec.builderFactories,
      buildOptions: buildSpec.buildOptions.copyWith(
        buildDirs: buildDirs,
        buildFilters: buildFilters,
      ),
      testingOverrides: buildSpec.testingOverrides,
      recentlyBootstrapped: false,
    ),
  );
}
