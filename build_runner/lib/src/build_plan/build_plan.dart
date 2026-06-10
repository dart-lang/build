// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart' hide Builder;
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:crypto/crypto.dart';
import 'package:watcher/watcher.dart';

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
import 'build_step_plan.dart';
import 'previous_build.dart';

part 'build_plan.g.dart';

/// Options and derived configuration for a build.
abstract class BuildPlan implements Built<BuildPlan, BuildPlanBuilder> {
  BuildSpec get buildSpec;
  PreviousBuild get previousBuild;
  BuildStepPlan get buildStepPlan;
  ReaderWriter get readerWriter;

  /// Outputs that conflict with the current build setup and must be deleted.
  BuiltList<AssetId> get conflictingOutputs;

  /// Sources and changes to sources before the build.
  BuildInputs get buildInputs;

  /// Per-build build dirs, which can differ from the global option in
  /// `BuildOptions`.
  BuiltSet<BuildDirectory> get buildDirs;

  /// Per-build build filters, which can differ from the global option in
  /// `BuildOptions`.
  BuiltSet<BuildFilter> get buildFilters;

  BuildPlan._();
  factory BuildPlan([void Function(BuildPlanBuilder) updates]) = _$BuildPlan;

  /// Loads the build plan for [buildSpec].
  ///
  /// Loads information about the previous build as [previousBuild].
  ///
  /// Files that should be deleted before restarting or building are tracked.
  /// Call [deleteFilesAndFolders] to delete them.
  ///
  /// [buildInputs] are resolved.
  static Future<BuildPlan> load(BuildSpec buildSpec) async {
    final previousBuild = await PreviousBuild.load(buildSpec);
    final buildPackages = buildSpec.buildPackages;
    final assetGraphJsonId = AssetId(
      buildPackages.outputRoot,
      assetGraphJsonPath,
    );

    final assetTracker = AssetTracker(
      buildSpec.readerWriter,
      buildPackages,
      buildSpec.buildConfigs,
    );
    final inputSources = await assetTracker.findInputSources();
    final cacheDirSources = await assetTracker.findCacheDirSources();

    Set<AssetId>? updates;
    final previousBuildState = previousBuild.buildState;
    if (previousBuildState != null) {
      updates = {
        ...inputSources,
        ...cacheDirSources,
        ...previousBuildState.sources,
        ...previousBuildState.actualOutputs,
      };
    }

    Set<AssetId> sourcesForBuildStepPlan;
    if (previousBuildState == null) {
      // Files marked for deletion are not inputs.
      inputSources.removeAll(previousBuild.incompatibleBuildOutputsToDelete);
      inputSources.remove(assetGraphJsonId);

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

    final conflictingOutputs = <AssetId>{};
    if (previousBuildState == null) {
      final conflictsInDeps = buildStepPlan.declaredOutputs
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

      conflictingOutputs.addAll(
        buildStepPlan.declaredOutputs
            .where((n) => buildPackages.outputPackages.contains(n.package))
            .where(inputSources.contains)
            .toSet(),
      );
    }

    return _createAndResolve(
      buildSpec: buildSpec,
      previousBuild: previousBuild,
      buildStepPlan: buildStepPlan,
      readerWriter: buildSpec.readerWriter.copyWith(
        generatedAssetHider: buildSpec.testingOverrides.flattenOutput
            ? const NoopGeneratedAssetHider()
            : buildStepPlan,
      ),
      conflictingOutputs: conflictingOutputs.toBuiltList(),
      buildDirs: buildSpec.buildOptions.buildDirs,
      buildFilters: buildSpec.buildOptions.buildFilters,
      updates: updates ?? {},
    );
  }

  /// Returns a copy of the plan with [previousBuild] updated for the next
  /// incremental build.
  BuildPlan withCompatiblePreviousBuild({
    required BuildState previousBuildState,
    required PhasedAssetDeps previousPhasedAssetDeps,
  }) => rebuild(
    (b) => b
      ..previousBuild.replace(
        previousBuild.updateForNextBuild(
          previousPhasedAssetDeps: previousPhasedAssetDeps,
          previousBuildState: previousBuildState,
        ),
      )
      ..conflictingOutputs.clear(),
  );

  Future<BuildPlan> updateForFileChanges(Set<AssetId> updates) {
    return _createAndResolve(
      buildSpec: buildSpec,
      previousBuild: previousBuild,
      buildStepPlan: buildStepPlan,
      readerWriter: readerWriter,
      conflictingOutputs: conflictingOutputs,
      buildDirs: buildDirs,
      buildFilters: buildFilters,
      updates: updates,
    );
  }

  /// Whether [phaseNumber] has different options to the previous build
  /// and must be fully rebuilt.
  bool phaseOptionsChanged(int phaseNumber) =>
      previousBuild.phaseOptionsChangedList[phaseNumber];

  /// Whether [actionNumber] has different options to the previous build
  /// and must be fully rebuilt.
  bool postBuildOptionsChanged(int actionNumber) =>
      previousBuild.postBuildOptionsChangedList[actionNumber];

  Future<void> deleteFilesAndFolders() async {
    // Hidden outputs are deleted if needed by deleting the entire folder. So,
    // only outputs in the source folder need to be deleted explicitly. Use a
    // `ReaderWriter` that only acts on the source folder.
    final cleanupReaderWriter = readerWriter.copyWith(
      generatedAssetHider: const NoopGeneratedAssetHider(),
    );

    if (buildInputs.cleanBuild) {
      final assetGraphJsonId = AssetId(
        buildSpec.buildPackages.outputRoot,
        assetGraphJsonPath,
      );
      final generatedOutputDirectoryId = AssetId(
        buildSpec.buildPackages.outputRoot,
        generatedOutputDirectory,
      );
      await cleanupReaderWriter.delete(assetGraphJsonId);
      await cleanupReaderWriter.deleteDirectory(generatedOutputDirectoryId);
    }

    for (final id in previousBuild.incompatibleBuildOutputsToDelete) {
      if (await cleanupReaderWriter.canRead(id)) {
        await cleanupReaderWriter.delete(id);
      }
    }
    for (final id in conflictingOutputs) {
      if (await cleanupReaderWriter.canRead(id)) {
        await cleanupReaderWriter.delete(id);
      }
    }
  }

  static Future<BuildPlan> _createAndResolve({
    required BuildSpec buildSpec,
    required PreviousBuild previousBuild,
    required BuildStepPlan buildStepPlan,
    required ReaderWriter readerWriter,
    required BuiltList<AssetId> conflictingOutputs,
    required BuiltSet<BuildDirectory> buildDirs,
    required BuiltSet<BuildFilter> buildFilters,
    required Set<AssetId> updates,
  }) async {
    final result = BuildInputsBuilder();

    final newDigests = <AssetId, Digest>{};
    final resolvedUpdates = <AssetId, ChangeType>{};
    final previousSources = <AssetId>{};

    final isCleanBuild = previousBuild.buildState == null;
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
        b.previousBuild.replace(previousBuild);
        b.buildStepPlan.replace(newBuildStepPlan);
        b.readerWriter = newReaderWriter;
        b.conflictingOutputs.replace(conflictingOutputs);
        b.buildInputs.replace(result.build());
        b.buildDirs.replace(buildDirs);
        b.buildFilters.replace(buildFilters);
      });
    }

    readerWriter.cache.invalidate(updates);

    final previousBuildState = previousBuild.buildState!;

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
      b.previousBuild.replace(previousBuild);
      b.buildStepPlan.replace(newBuildStepPlan);
      b.readerWriter = generatedReaderWriter;
      b.conflictingOutputs.replace(conflictingOutputs);
      b.buildInputs.replace(result.build());
      b.buildDirs.replace(buildDirs);
      b.buildFilters.replace(buildFilters);
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
