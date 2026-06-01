// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:build/build.dart';
import 'package:built_collection/built_collection.dart';

import 'package:watcher/watcher.dart';

import '../bootstrap/bootstrapper.dart';
import '../bootstrap/depfile.dart';
import '../build/build_state/asset_graph_json.dart';
import '../build/build_state/build_state.dart';
import '../build/build_state/exceptions.dart';
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
  final BuildStepPlan buildStepPlan;
  final BuildStepPlan? previousBuildStepPlan;

  final BuildState? _previousBuildState;
  final PhasedAssetDeps? previousPhasedAssetDeps;
  final bool restartIsNeeded;

  final Bootstrapper bootstrapper;
  final BuildState _buildState;
  final BuiltSet<AssetId>? updates;

  final BuiltSet<AssetId> changedInputs;
  final BuiltSet<AssetId> deletedAssets;
  final BuiltSet<AssetId> newPrimaryInputs;
  final Set<AssetId> invalidatedSources;

  /// Whether this is a clean build.
  ///
  /// If not, it's an incremental build.
  bool get cleanBuild => previousBuildState == null;

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

  BuildPlan({
    required this.buildPlanDigest,
    required this.builderFactories,
    required this.buildOptions,
    required this.testingOverrides,
    required this.buildPackages,
    required this.readerWriter,
    required this.buildConfigs,
    required this.buildStepPlan,
    required this.previousBuildStepPlan,
    required BuildState? previousBuildState,
    required this.previousPhasedAssetDeps,
    required this.restartIsNeeded,
    required this.bootstrapper,
    required BuildState buildState,
    required this.updates,
    required this.filesToDelete,
    required this.foldersToDelete,
    required this.triggersChanged,
    required BuiltList<bool> phaseOptionsChanged,
    required BuiltList<bool> postBuildOptionsChanged,
    required this.changedInputs,
    required this.deletedAssets,
    required this.newPrimaryInputs,
    required this.invalidatedSources,
  }) : _previousBuildState = previousBuildState,
       _buildState = buildState,
       _phaseOptionsChanged = phaseOptionsChanged,
       _postBuildOptionsChanged = postBuildOptionsChanged;

  /// Loads a build plan.
  ///
  /// Loads the package strucure and build configuration; prepares
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
    final compileFreshness =
        testingOverrides.checkBuilderFreshness
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
    final readerWriter = (testingOverrides.readerWriter ??
            ReaderWriter(buildPackages))
        .copyWith(cache: InMemoryFilesystemCache());
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
      } else {
        buildState = BuildState.create(
          sources: previousBuildState.sources.toSet(),
        );
      }
    }

    // Files marked for deletion are not inputs.
    inputSources.removeAll(filesToDelete);

    BuildStepPlan? previousBuildStepPlan;
    if (previousBuildState != null) {
      previousBuildStepPlan = BuildStepPlan.compute(
        buildPhases: buildPhases,
        placeholderIds: buildPackages.placeholderIds,
        sources: previousBuildState.sources,
      );
    }

    _RecreatedState recreated;
    try {
      recreated = await _recreateState(
        previousBuildState: previousBuildState,
        previousBuildStepPlan: previousBuildStepPlan,
        updates: updates ?? const {},
        inputSources: inputSources,
        buildPhases: buildPhases,
        buildPackages: buildPackages,
        readerWriter: readerWriter,
      );
    } on DuplicateAssetIdException catch (e) {
      buildLog.error(e.toString());
      throw const CannotBuildException();
    }

    final buildState = recreated.buildState;
    final buildStepPlan = recreated.buildStepPlan;

    final declaredAndActualOutputs = [
      ...buildStepPlan.declaredOutputs,
      ...buildState.actualPostOutputs,
    ];

    if (previousBuildState == null) {
      final conflictsInDeps =
          declaredAndActualOutputs
              .where((n) => !buildPackages.outputPackages.contains(n.package))
              .where(inputSources.contains)
              .toSet();
      if (conflictsInDeps.isNotEmpty) {
        buildLog.error(
          'There are existing files in dependencies which conflict '
          'with files that a Builder may produce. These must be removed or '
          'the Builders disabled before a build can continue: '
          '${conflictsInDeps.map((a) => a.uri).join('
')}',
        );
        throw const CannotBuildException();
      }
    }

    if (previousBuildState == null) {
      filesToDelete.addAll(
        declaredAndActualOutputs
            .where((n) => buildPackages.outputPackages.contains(n.package))
            .where(inputSources.contains)
            .toSet(),
      );
    }

    return BuildPlan(
      buildPlanDigest: buildPlanDigest,
      builderFactories: builderFactories,
      buildOptions: buildOptions,
      testingOverrides: testingOverrides,
      buildPackages: buildPackages,
      readerWriter: readerWriter,
      buildConfigs: buildConfigs,
      buildStepPlan: buildStepPlan,
      previousBuildStepPlan: previousBuildStepPlan,
      previousBuildState: previousBuildState,
      previousPhasedAssetDeps: previousPhasedAssetDeps,
      restartIsNeeded: restartIsNeeded,
      bootstrapper: bootstrapper,
      buildState: buildState,
      updates: updates?.build(),
      filesToDelete: filesToDelete.toBuiltList(),
      foldersToDelete: foldersToDelete.toBuiltList(),
      triggersChanged:
          !buildPlanDigest.hasSameTriggersAs(previousBuildPlanDigest),
      phaseOptionsChanged: buildPlanDigest.computeChangedPhaseOptions(
        previousBuildPlanDigest,
      ),
      postBuildOptionsChanged: buildPlanDigest.computeChangedPostBuildOptions(
        previousBuildPlanDigest,
      ),
      changedInputs: recreated.changedInputs,
      deletedAssets: recreated.deletedAssets,
      newPrimaryInputs: recreated.newPrimaryInputs,
      invalidatedSources: recreated.invalidatedSources,
    );
  }

  BuildPlan copyWith({
    BuildPlanDigest? buildPlanDigest,
    BuiltSet<BuildDirectory>? buildDirs,
    BuiltSet<BuildFilter>? buildFilters,
    ReaderWriter? readerWriter,
    bool? triggersChanged,
    BuildState? previousBuildState,
    PhasedAssetDeps? previousPhasedAssetDeps,
    BuiltList<bool>? phaseOptionsChanged,
    BuiltList<bool>? postBuildOptionsChanged,
    BuildStepPlan? buildStepPlan,
    BuildStepPlan? previousBuildStepPlan,
    BuildState? buildState,
    BuiltSet<AssetId>? changedInputs,
    BuiltSet<AssetId>? deletedAssets,
    BuiltSet<AssetId>? newPrimaryInputs,
    Set<AssetId>? invalidatedSources,
  }) => BuildPlan(
    buildPlanDigest: buildPlanDigest ?? this.buildPlanDigest,
    buildStepPlan: buildStepPlan ?? this.buildStepPlan,
    previousBuildStepPlan: previousBuildStepPlan ?? this.previousBuildStepPlan,
    builderFactories: builderFactories,
    buildOptions: buildOptions.copyWith(
      buildDirs: buildDirs,
      buildFilters: buildFilters,
    ),
    testingOverrides: testingOverrides,
    buildPackages: buildPackages,
    buildConfigs: buildConfigs,
    readerWriter: readerWriter ?? this.readerWriter,
    previousBuildState: previousBuildState ?? _previousBuildState,
    previousPhasedAssetDeps:
        previousPhasedAssetDeps ?? this.previousPhasedAssetDeps,
    restartIsNeeded: restartIsNeeded,
    bootstrapper: bootstrapper,
    buildState: buildState ?? _buildState,
    updates: updates,
    filesToDelete: filesToDelete,
    foldersToDelete: foldersToDelete,
    triggersChanged: triggersChanged ?? this.triggersChanged,
    phaseOptionsChanged: phaseOptionsChanged ?? _phaseOptionsChanged,
    postBuildOptionsChanged:
        postBuildOptionsChanged ?? _postBuildOptionsChanged,
    changedInputs: changedInputs ?? this.changedInputs,
    deletedAssets: deletedAssets ?? this.deletedAssets,
    newPrimaryInputs: newPrimaryInputs ?? this.newPrimaryInputs,
    invalidatedSources: invalidatedSources ?? this.invalidatedSources,
  );

  /// Returns a copy of the plan updated for the next incremental build.
  ///
  /// Updates [previousPhasedAssetDeps] from the build result.
  ///
  /// Sets [cleanBuild], [triggersChanged], `phaseOptionsChanged` and
  /// `postBuildOptionsChanged` to `false`.
  BuildPlan updateForResult({
    required BuildState previousBuildState,
    PhasedAssetDeps? previousPhasedAssetDeps,
  }) =>
      copyWith(
        triggersChanged: false,
        previousBuildState: previousBuildState,
        previousBuildStepPlan: this.buildStepPlan,
        previousPhasedAssetDeps: previousPhasedAssetDeps,
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
        buildState: BuildState.create(sources: const {}),
        changedInputs: BuiltSet<AssetId>(),
        deletedAssets: BuiltSet<AssetId>(),
        newPrimaryInputs: BuiltSet<AssetId>(),
        invalidatedSources: const {},
      );

  BuildState? get previousBuildState => _previousBuildState;

  BuildState get buildState => _buildState;

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

  Future<BuildPlan> applyUpdates(Set<AssetId> updates) async {
    final recreated = await _recreateState(
      previousBuildState: previousBuildState,
      previousBuildStepPlan: previousBuildStepPlan,
      updates: updates,
      inputSources: const {},
      buildPhases: buildPhases,
      buildPackages: buildPackages,
      readerWriter: readerWriter,
    );
    return copyWith(
      buildStepPlan: recreated.buildStepPlan,
      buildState: recreated.buildState,
      changedInputs: recreated.changedInputs,
      deletedAssets: recreated.deletedAssets,
      newPrimaryInputs: recreated.newPrimaryInputs,
      invalidatedSources: recreated.invalidatedSources,
    );
  }

  static Future<_RecreatedState> _recreateState({
    required BuildState? previousBuildState,
    required BuildStepPlan? previousBuildStepPlan,
    required Set<AssetId> updates,
    required Set<AssetId> inputSources,
    required BuildPhases buildPhases,
    required BuildPackages buildPackages,
    required ReaderWriter readerWriter,
  }) async {
    final activeReaderWriter = readerWriter.copyWith(
      generatedAssetHider:
          previousBuildState ?? const NoopGeneratedAssetHider(),
    );
    readerWriter = activeReaderWriter;
    final changedInputs = <AssetId>{};
    final deletedAssets = <AssetId>{};
    final newPrimaryInputs = <AssetId>{};

    if (previousBuildState == null) {
      final buildState = BuildState.create(sources: inputSources);
      final buildStepPlan = BuildStepPlan.compute(
        buildPhases: buildPhases,
        placeholderIds: buildPackages.placeholderIds,
        sources: buildState.sources,
      );
      return _RecreatedState(
        buildState: buildState,
        buildStepPlan: buildStepPlan,
      previousBuildStepPlan: previousBuildStepPlan,
        changedInputs: BuiltSet<AssetId>(),
        deletedAssets: BuiltSet<AssetId>(),
        newPrimaryInputs: BuiltSet<AssetId>(),
        invalidatedSources: const {},
      );
    }

    readerWriter.cache.invalidate(updates);

    // 1. Identify adds, removes, modifies from updates.
    final adds = <AssetId>{};
    final removes = <AssetId>{};
    final modifies = <AssetId>{};
    final previousSources = <AssetId>{};
    for (final id in updates) {
      final oldIsSource = previousBuildState.isSource(id);
      if (oldIsSource) {
        previousSources.add(id);
      }
      final oldExisted = previousBuildState.isFile(
        buildStepPlan: previousBuildStepPlan,
        id: id,
      );
      var exists = false;
      if (await readerWriter.canRead(id)) {
        exists = true;
      }

      if (oldExisted && !exists) {
        removes.add(id);
      } else if (!oldExisted && exists) {
        adds.add(id);
      } else if (oldExisted && exists) {
        modifies.add(id);
      }
    }

    // 2. Compute new sources.
    final newSources =
        previousBuildState.sources.toSet()
          ..addAll(adds)
          ..removeAll(removes);

    // 3. Create the NEW BuildState.
    final newBuildState = BuildState.create(sources: newSources);
    final newBuildStepPlan = BuildStepPlan.compute(
      buildPhases: buildPhases,
      placeholderIds: buildPackages.placeholderIds,
      sources: newBuildState.sources,
    );

    // 4. Populate changedInputs, deletedAssets, newPrimaryInputs.
    changedInputs.addAll(adds);
    newPrimaryInputs.addAll(adds);
    deletedAssets.addAll(removes);

    // 5. Check modified sources for content changes.
    readerWriter.cache.invalidate(modifies);
    final resolvedUpdates = <AssetId, ChangeType>{};
    for (final id in modifies) {
      if (newSources.contains(id)) {
        final oldDigest = previousBuildState.digestOfSource(id);
        if (oldDigest != null) {
          try {
            final newDigest = await readerWriter.digest(id);
            if (oldDigest != newDigest) {
              changedInputs.add(id);
              newBuildState.updateSourceDigest(id, newDigest);
              resolvedUpdates[id] = ChangeType.MODIFY;
            } else {
              newBuildState.updateSourceDigest(id, oldDigest);
            }
          } catch (_) {
            // Treat as missing.
            newBuildState.addMissingSource(id);
            deletedAssets.add(id);
            resolvedUpdates[id] = ChangeType.REMOVE;
          }
        }
      }
    }
    for (final id in adds) {
      resolvedUpdates[id] = ChangeType.ADD;
    }
    for (final id in removes) {
      resolvedUpdates[id] = ChangeType.REMOVE;
    }

    // 6. Copy unchanged source digests.
    for (final id in newSources) {
      if (!adds.contains(id) && !modifies.contains(id)) {
        final digest = previousBuildState.digestOfSource(id);
        newBuildState.updateSourceDigest(id, digest);
      }
    }

    // 7. Find outputs to delete.
    final outputsToDelete = <AssetId>[];
    for (final id in previousBuildStepPlan!.declaredOutputs) {
      if (!newBuildStepPlan.isDeclaredOutput(id)) {
        if (previousBuildState.isActualOutput(
          buildStepPlan: previousBuildStepPlan,
          id: id,
        )) {
          outputsToDelete.add(id);
        }
      }
    }
    for (final id in outputsToDelete) {
      await readerWriter.delete(id);
    }
    deletedAssets.addAll(outputsToDelete);

    // 8. Populate missingSources in the new BuildState.
    final stillMissing = previousBuildState.missingSources.difference(adds);
    for (final id in stillMissing) {
      newBuildState.addMissingSource(id);
    }
    for (final id in removes) {
      newBuildState.addMissingSource(id);
    }

    // 9. Compute invalidatedSources to return.
    final invalidatedSources = <AssetId>{};
    for (final entry in resolvedUpdates.entries) {
      final id = entry.key;
      final changeType = entry.value;
      if (changeType != ChangeType.ADD && previousSources.contains(id)) {
        invalidatedSources.add(id);
      }
    }

    return _RecreatedState(
      buildState: newBuildState,
      buildStepPlan: newBuildStepPlan,
      changedInputs: BuiltSet<AssetId>.of(changedInputs),
      deletedAssets: BuiltSet<AssetId>.of(deletedAssets),
      newPrimaryInputs: BuiltSet<AssetId>.of(newPrimaryInputs),
      invalidatedSources: invalidatedSources,
    );
  }
}

class _RecreatedState {
  final BuildState buildState;
  final BuildStepPlan buildStepPlan;
  final BuildStepPlan? previousBuildStepPlan;
  final BuiltSet<AssetId> changedInputs;
  final BuiltSet<AssetId> deletedAssets;
  final BuiltSet<AssetId> newPrimaryInputs;
  final Set<AssetId> invalidatedSources;
  _RecreatedState({
    required this.buildState,
    required this.buildStepPlan,
    required this.previousBuildStepPlan,
    required this.changedInputs,
    required this.deletedAssets,
    required this.newPrimaryInputs,
    required this.invalidatedSources,
  });
}
