// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:build/build.dart';
import 'package:built_collection/built_collection.dart';
import 'package:crypto/crypto.dart';
import 'package:watcher/watcher.dart';

import '../bootstrap/bootstrapper.dart';
import '../bootstrap/depfile.dart';
import '../build/build_state/asset_graph_json.dart';
import '../build/build_state/build_state.dart';

import '../build/library_cycle_graph/phased_asset_deps.dart';
import '../constants.dart';
import '../exceptions.dart';
import '../io/asset_tracker.dart';
import '../io/filesystem_cache.dart';
import '../io/generated_asset_hider.dart';
import '../io/reader_writer.dart';
import '../logging/build_log.dart';
import 'build_configs.dart';
import 'build_directory.dart';
import 'build_filter.dart';
import 'build_inputs.dart';
import 'build_options.dart';
import 'build_packages.dart';
import 'build_phase_creator.dart';
import 'build_plan_digest.dart';
import 'build_step_plan.dart';
import 'builder_definition.dart';
import 'builder_factories.dart';
import 'testing_overrides.dart';

/// Options and derived configuration for a build.
class BuildPlan {
  final BuildPlanDigest buildPlanDigest;

  final BuilderFactories builderFactories;
  final BuildOptions buildOptions;
  final TestingOverrides testingOverrides;

  final BuildPackages buildPackages;
  final ReaderWriter readerWriter;
  final BuildConfigs buildConfigs;
  final BuildState? previousBuildState;
  final PhasedAssetDeps? previousPhasedAssetDeps;

  final BuildStepPlan buildStepPlan;
  final bool restartIsNeeded;

  final Bootstrapper bootstrapper;

  /// Whether build triggers config changed since the previous build.
  final bool triggersChanged;

  /// Whether phase options per phase changed since the previous build.
  final BuiltList<bool> _phaseOptionsChanged;

  /// Whether post process phase options per phase changed since the previous
  /// build.
  final BuiltList<bool> _postBuildOptionsChanged;

  /// Files to delete before restarting or before the next build.
  ///
  /// - Outputs from the previous build.
  /// - Files on disk that conflict with outputs of the current build.
  /// - The build state, if it's invalid.
  ///
  /// Call [deleteFilesAndFolders] to delete them.
  final BuiltList<AssetId> filesToDelete;

  /// Folders to delete before restarting or before the next build.
  ///
  /// Call [deleteFilesAndFolders] to delete them.
  final BuiltList<AssetId> foldersToDelete;

  /// Sources and changes to sources before the build.
  final BuildInputs buildInputs;

  BuildPlan({
    required this.buildPlanDigest,
    required this.builderFactories,
    required this.buildOptions,
    required this.testingOverrides,
    required this.buildPackages,
    required this.readerWriter,
    required this.buildConfigs,
    required this.buildStepPlan,
    required this.previousBuildState,
    required this.previousPhasedAssetDeps,
    required this.restartIsNeeded,
    required this.bootstrapper,
    required this.filesToDelete,
    required this.foldersToDelete,
    required this.triggersChanged,
    required BuiltList<bool> phaseOptionsChanged,
    required BuiltList<bool> postBuildOptionsChanged,
    required this.buildInputs,
  }) : _phaseOptionsChanged = phaseOptionsChanged,
       _postBuildOptionsChanged = postBuildOptionsChanged;

  /// Loads a build plan.
  ///
  /// Loads the package structure and build configuration; prepares
  /// [readerWriter], deduces the buildPhases that will run, deserializes and
  /// checks the `BuildState`.
  ///
  /// If the build state indicates a restart is needed, [restartIsNeeded] will
  /// be set. Otherwise, if it's valid, the deserialized build state is
  /// available from [previousBuildState].
  ///
  /// Files that should be deleted before restarting or building are accumulated
  /// in [filesToDelete] and [foldersToDelete]. Call [deleteFilesAndFolders] to
  /// delete them.
  ///
  /// Set [recentlyBootstrapped] to false to do checks that are also done during
  /// bootstrapping.
  static Future<BuildPlan> load({
    required BuilderFactories builderFactories,
    required BuildOptions buildOptions,
    required TestingOverrides testingOverrides,
    bool recentlyBootstrapped = true,
  }) async {
    final bootstrapper = Bootstrapper(
      buildPaths: buildOptions.buildPaths,
      compileStrategy: buildOptions.compileStrategy,
    );
    var restartIsNeeded = false;
    final compileFreshness = testingOverrides.checkBuilderFreshness
        ? await bootstrapper.checkCompileFreshness(
            digestsAreFresh: recentlyBootstrapped,
          )
        : FreshnessResult(outputIsFresh: true, digest: 'dummy_digest');
    if (!compileFreshness.outputIsFresh) {
      restartIsNeeded = true;
    }

    final buildPackages =
        testingOverrides.buildPackages ??
        await BuildPackages.forPaths(buildOptions.buildPaths);
    final readerWriter =
        (testingOverrides.readerWriter ?? ReaderWriter(buildPackages)).copyWith(
          cache: InMemoryFilesystemCache(),
        );
    final buildConfigs = await BuildConfigs.load(
      readerWriter: readerWriter,
      buildPackages: buildPackages,
      testingOverrides: testingOverrides,
      configKey: buildOptions.configKey,
    );

    var builderDefinitions =
        testingOverrides.builderDefinitions ??
        await AbstractBuilderDefinition.load(
          buildPackages: buildPackages,
          readerWriter: readerWriter,
        );

    // Check that there is a factory available for every builder, if not the
    // config has changed since the script was written and a restart is needed.
    if (!builderFactories.hasFactoriesFor(builderDefinitions)) {
      restartIsNeeded = true;
      builderDefinitions = BuiltList();
    }

    final buildPhases =
        testingOverrides.buildPhases ??
        await BuildPhaseCreator(
          builderFactories: builderFactories,
          buildPackages: buildPackages,
          buildConfigs: buildConfigs,
          builderDefinitions: builderDefinitions,
          builderConfigOverrides: buildOptions.builderConfigOverrides,
          isReleaseBuild: buildOptions.isReleaseBuild,
          workspace: buildOptions.buildPaths.buildWorkspace,
        ).createBuildPhases();
    buildPhases.checkOutputLocations(buildPackages.outputPackages);

    final buildPlanDigest = BuildPlanDigest(
      compileDigest: compileFreshness.digest,
      buildConfigs: buildConfigs,
      buildPhases: buildPhases,
      buildPackages: buildPackages,
    );

    final assetGraphJsonId = AssetId(
      buildPackages.outputRoot,
      assetGraphJsonPath,
    );
    final generatedOutputDirectoryId = AssetId(
      buildPackages.outputRoot,
      generatedOutputDirectory,
    );
    BuildPlanDigest? previousBuildPlanDigest;
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
        if (restartIsNeeded ||
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
      buildConfigs,
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

      if (restartIsNeeded) {
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
        buildPhases: buildPhases,
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
      buildPhases: buildPhases,
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
      generatedAssetHider: testingOverrides.flattenOutput
          ? const NoopGeneratedAssetHider()
          : buildStepPlan,
    );

    return _createAndResolve(
      buildPlanDigest: buildPlanDigest,
      builderFactories: builderFactories,
      buildOptions: buildOptions,
      testingOverrides: testingOverrides,
      buildPackages: buildPackages,
      readerWriter: finalReaderWriter,
      buildConfigs: buildConfigs,
      buildStepPlan: buildStepPlan,
      previousBuildState: previousBuildState,
      previousPhasedAssetDeps: previousPhasedAssetDeps,
      restartIsNeeded: restartIsNeeded,
      bootstrapper: bootstrapper,
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

  BuildPlan copyWith({
    BuildPlanDigest? buildPlanDigest,
    BuiltSet<BuildDirectory>? buildDirs,
    BuiltSet<BuildFilter>? buildFilters,
    ReaderWriter? readerWriter,
    bool? triggersChanged,
    PhasedAssetDeps? previousPhasedAssetDeps,
    BuiltList<bool>? phaseOptionsChanged,
    BuiltList<bool>? postBuildOptionsChanged,
    BuildStepPlan? buildStepPlan,
    BuildState? previousBuildState,
    BuildInputs? buildInputs,
  }) => BuildPlan(
    buildPlanDigest: buildPlanDigest ?? this.buildPlanDigest,
    builderFactories: builderFactories,
    buildOptions: buildOptions.copyWith(
      buildDirs: buildDirs,
      buildFilters: buildFilters,
    ),
    testingOverrides: testingOverrides,
    buildPackages: buildPackages,
    buildConfigs: buildConfigs,
    readerWriter: readerWriter ?? this.readerWriter,
    buildStepPlan: buildStepPlan ?? this.buildStepPlan,
    previousBuildState: previousBuildState ?? this.previousBuildState,
    previousPhasedAssetDeps:
        previousPhasedAssetDeps ?? this.previousPhasedAssetDeps,
    restartIsNeeded: restartIsNeeded,
    bootstrapper: bootstrapper,
    filesToDelete: filesToDelete,
    foldersToDelete: foldersToDelete,
    triggersChanged: triggersChanged ?? this.triggersChanged,
    phaseOptionsChanged: phaseOptionsChanged ?? _phaseOptionsChanged,
    postBuildOptionsChanged:
        postBuildOptionsChanged ?? _postBuildOptionsChanged,
    buildInputs: buildInputs ?? this.buildInputs,
  );

  /// Returns a copy of the plan updated for the next incremental build.
  ///
  /// Updates [previousPhasedAssetDeps] from the build result.
  ///
  /// Sets [triggersChanged], `phaseOptionsChanged` and
  /// `postBuildOptionsChanged` to `false`.
  BuildPlan updateForResult({
    PhasedAssetDeps? previousPhasedAssetDeps,
    BuildState? previousBuildState,
  }) => copyWith(
    triggersChanged: false,
    previousPhasedAssetDeps: previousPhasedAssetDeps,
    previousBuildState: previousBuildState,
    phaseOptionsChanged: BuiltList<bool>.from(
      List.filled(
        buildStepPlan.buildPhases.inBuildPhasesOptionsDigests.length,
        false,
      ),
    ),
    postBuildOptionsChanged: BuiltList<bool>.from(
      List.filled(
        buildStepPlan.buildPhases.postBuildActionsOptionsDigests.length,
        false,
      ),
    ),
  );

  Future<BuildPlan> updateForFileChanges(Set<AssetId> updates) {
    return _createAndResolve(
      buildPlanDigest: buildPlanDigest,
      builderFactories: builderFactories,
      buildOptions: buildOptions,
      testingOverrides: testingOverrides,
      buildPackages: buildPackages,
      readerWriter: readerWriter,
      buildConfigs: buildConfigs,
      buildStepPlan: buildStepPlan,
      previousBuildState: previousBuildState,
      previousPhasedAssetDeps: previousPhasedAssetDeps,
      restartIsNeeded: restartIsNeeded,
      bootstrapper: bootstrapper,
      filesToDelete: filesToDelete,
      foldersToDelete: foldersToDelete,
      triggersChanged: triggersChanged,
      phaseOptionsChanged: _phaseOptionsChanged,
      postBuildOptionsChanged: _postBuildOptionsChanged,
      updates: updates,
    );
  }

  /// Whether [phaseNumber] has different options to the previous build
  /// and must be fully rebuilt.
  bool phaseOptionsChanged(int phaseNumber) =>
      _phaseOptionsChanged[phaseNumber];

  /// Whether [actionNumber] has different options to the previous build
  /// and must be fully rebuilt.
  bool postBuildOptionsChanged(int actionNumber) =>
      _postBuildOptionsChanged[actionNumber];

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
    required BuildPlanDigest buildPlanDigest,
    required BuilderFactories builderFactories,
    required BuildOptions buildOptions,
    required TestingOverrides testingOverrides,
    required BuildPackages buildPackages,
    required ReaderWriter readerWriter,
    required BuildConfigs buildConfigs,
    required BuildStepPlan buildStepPlan,
    required BuildState? previousBuildState,
    required PhasedAssetDeps? previousPhasedAssetDeps,
    required bool restartIsNeeded,
    required Bootstrapper bootstrapper,
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
        placeholderIds: buildPackages.placeholderIds,
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
        generatedAssetHider: testingOverrides.flattenOutput
            ? const NoopGeneratedAssetHider()
            : newBuildStepPlan,
      );
      return BuildPlan(
        buildPlanDigest: buildPlanDigest,
        builderFactories: builderFactories,
        buildOptions: buildOptions,
        testingOverrides: testingOverrides,
        buildPackages: buildPackages,
        readerWriter: newReaderWriter,
        buildConfigs: buildConfigs,
        buildStepPlan: newBuildStepPlan,
        previousBuildState: previousBuildState,
        previousPhasedAssetDeps: previousPhasedAssetDeps,
        restartIsNeeded: restartIsNeeded,
        bootstrapper: bootstrapper,
        filesToDelete: filesToDelete,
        foldersToDelete: foldersToDelete,
        triggersChanged: triggersChanged,
        phaseOptionsChanged: phaseOptionsChanged,
        postBuildOptionsChanged: postBuildOptionsChanged,
        buildInputs: result.build(),
      );
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
      placeholderIds: buildPackages.placeholderIds,
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
      generatedAssetHider: testingOverrides.flattenOutput
          ? const NoopGeneratedAssetHider()
          : newBuildStepPlan,
    );
    for (final id in deletedOutputs) {
      await generatedReaderWriter.delete(id);
    }

    return BuildPlan(
      buildPlanDigest: buildPlanDigest,
      builderFactories: builderFactories,
      buildOptions: buildOptions,
      testingOverrides: testingOverrides,
      buildPackages: buildPackages,
      readerWriter: generatedReaderWriter,
      buildConfigs: buildConfigs,
      buildStepPlan: newBuildStepPlan,
      previousBuildState: previousBuildState,
      previousPhasedAssetDeps: previousPhasedAssetDeps,
      restartIsNeeded: restartIsNeeded,
      bootstrapper: bootstrapper,
      filesToDelete: filesToDelete,
      foldersToDelete: foldersToDelete,
      triggersChanged: triggersChanged,
      phaseOptionsChanged: phaseOptionsChanged,
      postBuildOptionsChanged: postBuildOptionsChanged,
      buildInputs: result.build(),
    );
  }

  /// Reloads the build plan.
  ///
  /// Works just like a new load of the build plan, but sets
  /// `recentlyBootstrapped` to `false` to redo checks from bootstrapping.
  ///
  /// The caller must call [deleteFilesAndFolders] on the result and check
  /// [restartIsNeeded].
  Future<BuildPlan> reload() => BuildPlan.load(
    builderFactories: builderFactories,
    buildOptions: buildOptions,
    testingOverrides: testingOverrides,
    recentlyBootstrapped: false,
  );
}
