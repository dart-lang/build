// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:build/build.dart';
import 'package:built_collection/built_collection.dart';

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

  final BuildState? _previousBuildState;
  bool _previousBuildStateWasTaken;
  final PhasedAssetDeps? previousPhasedAssetDeps;
  final bool restartIsNeeded;

  final Bootstrapper bootstrapper;
  final BuildState _buildState;
  bool _buildStateWasTaken;
  final BuiltSet<AssetId>? updates;

  /// Whether this is a clean build.
  ///
  /// If not, it's an incremental build.
  final bool cleanBuild;

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
    required BuildState? previousBuildState,
    required bool previousBuildStateWasTaken,
    required this.previousPhasedAssetDeps,
    required this.restartIsNeeded,
    required this.bootstrapper,
    required BuildState buildState,
    required bool buildStateWasTaken,
    required this.updates,
    required this.filesToDelete,
    required this.foldersToDelete,
    required this.cleanBuild,
    required this.triggersChanged,
    required BuiltList<bool> phaseOptionsChanged,
    required BuiltList<bool> postBuildOptionsChanged,
  }) : _previousBuildState = previousBuildState,
       _previousBuildStateWasTaken = previousBuildStateWasTaken,
       _buildState = buildState,
       _buildStateWasTaken = buildStateWasTaken,
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
  /// available from [takePreviousBuildState].
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

    BuildState? buildState;
    Set<AssetId>? updates;
    if (previousBuildState != null) {
      updates = {
        ...inputSources,
        ...cacheDirSources,
        ...previousBuildState.sources,
        ...previousBuildState.actualOutputs,
      };
      buildState = previousBuildState.copyForNextBuild();

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

    if (buildState == null) {
      // Files marked for deletion are not inputs.
      inputSources.removeAll(filesToDelete);

      // Build steps are computed twice: first to identify inputs that are
      // actually outputs and remove them from the input set.
      final declaredOutputs =
          BuildStepPlan.compute(
            buildPhases: buildPhases,
            placeholderIds: buildPackages.placeholderIds,
            sources: inputSources,
          ).declaredOutputs;
      final inputSourcesWithoutOutputs = Set<AssetId>.from(inputSources);
      for (final output in declaredOutputs) {
        inputSourcesWithoutOutputs.remove(output);
      }

      try {
        buildState = BuildState.create(sources: inputSourcesWithoutOutputs);
      } on DuplicateAssetIdException catch (e) {
        buildLog.error(e.toString());
        throw const CannotBuildException();
      }
    }

    final buildStepPlan = BuildStepPlan.compute(
      buildPhases: buildPhases,
      placeholderIds: buildPackages.placeholderIds,
      sources: buildState.sources,
    );
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

    return BuildPlan(
      buildPlanDigest: buildPlanDigest,
      builderFactories: builderFactories,
      buildOptions: buildOptions,
      testingOverrides: testingOverrides,
      buildPackages: buildPackages,
      readerWriter: readerWriter,
      buildConfigs: buildConfigs,
      buildStepPlan: buildStepPlan,
      previousBuildState: previousBuildState,
      previousBuildStateWasTaken: false,
      previousPhasedAssetDeps: previousPhasedAssetDeps,
      restartIsNeeded: restartIsNeeded,
      bootstrapper: bootstrapper,
      buildState: buildState,
      buildStateWasTaken: false,
      updates: updates?.build(),
      filesToDelete: filesToDelete.toBuiltList(),
      foldersToDelete: foldersToDelete.toBuiltList(),
      cleanBuild: previousBuildState == null,
      triggersChanged:
          !buildPlanDigest.hasSameTriggersAs(previousBuildPlanDigest),
      phaseOptionsChanged: buildPlanDigest.computeChangedPhaseOptions(
        previousBuildPlanDigest,
      ),
      postBuildOptionsChanged: buildPlanDigest.computeChangedPostBuildOptions(
        previousBuildPlanDigest,
      ),
    );
  }

  BuildPlan copyWith({
    BuildPlanDigest? buildPlanDigest,
    BuiltSet<BuildDirectory>? buildDirs,
    BuiltSet<BuildFilter>? buildFilters,
    ReaderWriter? readerWriter,
    bool? cleanBuild,
    bool? triggersChanged,
    PhasedAssetDeps? previousPhasedAssetDeps,
    BuiltList<bool>? phaseOptionsChanged,
    BuiltList<bool>? postBuildOptionsChanged,
    BuildStepPlan? buildStepPlan,
  }) => BuildPlan(
    buildPlanDigest: buildPlanDigest ?? this.buildPlanDigest,
    buildStepPlan: buildStepPlan ?? this.buildStepPlan,
    builderFactories: builderFactories,
    buildOptions: buildOptions.copyWith(
      buildDirs: buildDirs,
      buildFilters: buildFilters,
    ),
    testingOverrides: testingOverrides,
    buildPackages: buildPackages,
    buildConfigs: buildConfigs,
    readerWriter: readerWriter ?? this.readerWriter,
    previousBuildState: _previousBuildState,
    previousBuildStateWasTaken: _previousBuildStateWasTaken,
    previousPhasedAssetDeps:
        previousPhasedAssetDeps ?? this.previousPhasedAssetDeps,
    restartIsNeeded: restartIsNeeded,
    bootstrapper: bootstrapper,
    buildState: _buildState,
    buildStateWasTaken: _buildStateWasTaken,
    updates: updates,
    filesToDelete: filesToDelete,
    foldersToDelete: foldersToDelete,
    cleanBuild: cleanBuild ?? this.cleanBuild,
    triggersChanged: triggersChanged ?? this.triggersChanged,
    phaseOptionsChanged: phaseOptionsChanged ?? _phaseOptionsChanged,
    postBuildOptionsChanged:
        postBuildOptionsChanged ?? _postBuildOptionsChanged,
  );

  /// Returns a copy of the plan updated for the next incremental build.
  ///
  /// Updates [previousPhasedAssetDeps] from the build result.
  ///
  /// Sets [cleanBuild], [triggersChanged], `phaseOptionsChanged` and
  /// `postBuildOptionsChanged` to `false`.
  BuildPlan updateForResult({PhasedAssetDeps? previousPhasedAssetDeps}) =>
      copyWith(
        cleanBuild: false,
        triggersChanged: false,
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
      );

  /// Returns a copy of the plan with [buildStepPlan] updated for changed input
  /// sources.
  BuildPlan updateForSources(Iterable<AssetId> sources) {
    return copyWith(
      buildStepPlan: BuildStepPlan.compute(
        buildPhases: buildStepPlan.buildPhases,
        placeholderIds: buildPackages.placeholderIds,
        sources: sources,
      ),
    );
  }

  /// Takes the loaded [BuildState], which may be `null` if none could be
  /// loaded or if it was invalid.
  ///
  /// Subsequent calls will throw. This is because [BuildState] is mutable, so
  /// the initial loaded state is only available once.
  BuildState? takePreviousBuildState() {
    if (_previousBuildStateWasTaken) throw StateError('Already taken.');
    _previousBuildStateWasTaken = true;
    return _previousBuildState;
  }

  /// Takes the [BuildState] for the build.
  ///
  /// Subsequent calls will throw. This is because [BuildState] is mutable, so
  /// the initial state is only available once.
  BuildState takeBuildState() {
    if (_buildStateWasTaken) throw StateError('Already taken.');
    _buildStateWasTaken = true;
    return _buildState;
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
