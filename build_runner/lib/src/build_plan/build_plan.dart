// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:build/build.dart';
import 'package:build/experiments.dart';
import 'package:built_collection/built_collection.dart';
import 'package:watcher/watcher.dart';

import '../bootstrap/bootstrapper.dart';
import '../build/asset_graph/exceptions.dart';
import '../build/asset_graph/graph.dart';
import '../constants.dart';
import '../exceptions.dart';
import '../io/asset_tracker.dart';
import '../io/generated_asset_hider.dart';
import '../io/reader_writer.dart';
import '../logging/build_log.dart';
import 'build_configs.dart';
import 'build_directory.dart';
import 'build_filter.dart';
import 'build_options.dart';
import 'build_packages.dart';
import 'build_phase_creator.dart';
import 'build_phases.dart';
import 'builder_definition.dart';
import 'builder_factories.dart';
import 'testing_overrides.dart';

/// Options and derived configuration for a build.
class BuildPlan {
  final BuilderFactories builderFactories;
  final BuildOptions buildOptions;
  final TestingOverrides testingOverrides;

  final BuildPackages buildPackages;
  final ReaderWriter readerWriter;
  final BuildConfigs buildConfigs;
  final BuildPhases buildPhases;

  final AssetGraph? _previousAssetGraph;
  bool _previousAssetGraphWasTaken;
  final bool restartIsNeeded;

  final Bootstrapper bootstrapper;
  final AssetGraph _assetGraph;
  bool _assetGraphWasTaken;
  final BuiltMap<AssetId, ChangeType>? updates;

  /// Files to delete before restarting or before the next build.
  ///
  /// - Outputs from the previous build.
  /// - Files on disk that conflict with outputs of the current build.
  /// - The asset graph, if it's invalid.
  ///
  /// Call [deleteFilesAndFolders] to delete them.
  final BuiltList<AssetId> filesToDelete;

  /// Folders to delete before restarting or before the next build.
  ///
  /// Call [deleteFilesAndFolders] to delete them.
  final BuiltList<AssetId> foldersToDelete;

  BuildPlan({
    required this.builderFactories,
    required this.buildOptions,
    required this.testingOverrides,
    required this.buildPackages,
    required this.readerWriter,
    required this.buildConfigs,
    required this.buildPhases,
    required AssetGraph? previousAssetGraph,
    required bool previousAssetGraphWasTaken,
    required this.restartIsNeeded,
    required this.bootstrapper,
    required AssetGraph assetGraph,
    required bool assetGraphWasTaken,
    required this.updates,
    required this.filesToDelete,
    required this.foldersToDelete,
  }) : _previousAssetGraph = previousAssetGraph,
       _previousAssetGraphWasTaken = previousAssetGraphWasTaken,
       _assetGraph = assetGraph,
       _assetGraphWasTaken = assetGraphWasTaken;

  /// Loads a build plan.
  ///
  /// Loads the package strucure and build configuration; prepares
  /// [readerWriter], deduces the [buildPhases] that will run, deserializes and
  /// checks the `AssetGraph`.
  ///
  /// If the asset graph indicates a restart is needed, [restartIsNeeded] will
  /// be set. Otherwise, if it's valid, the deserialized asset graph is
  /// available from [takePreviousAssetGraph].
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
      compileAot: buildOptions.forceAot ? true : false,
    );
    var restartIsNeeded = false;
    final kernelFreshness = await bootstrapper.checkCompileFreshness(
      digestsAreFresh: recentlyBootstrapped,
    );
    if (!kernelFreshness.outputIsFresh) {
      restartIsNeeded = true;
    }

    final buildPackages =
        testingOverrides.buildPackages ??
        await BuildPackages.forThisPackage(workspace: buildOptions.workspace);

    final readerWriter =
        testingOverrides.readerWriter ?? ReaderWriter(buildPackages);

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
        ).createBuildPhases();
    buildPhases.checkOutputLocations(buildPackages.packagesInBuild);

    AssetGraph? previousAssetGraph;
    final filesToDelete = <AssetId>{};
    final foldersToDelete = <AssetId>{};

    final assetGraphId = AssetId(buildPackages.outputRoot.name, assetGraphPath);
    final generatedOutputDirectoryId = AssetId(
      buildPackages.outputRoot.name,
      generatedOutputDirectory,
    );

    if (await readerWriter.canRead(assetGraphId)) {
      previousAssetGraph = AssetGraph.deserialize(
        await readerWriter.readAsBytes(assetGraphId),
      );
      if (previousAssetGraph != null) {
        final buildPhasesChanged =
            buildPhases.digest != previousAssetGraph.buildPhasesDigest;
        final pkgVersionsChanged =
            previousAssetGraph.packageLanguageVersions !=
            buildPackages.languageVersions;
        final enabledExperimentsChanged =
            previousAssetGraph.enabledExperiments != enabledExperiments.build();
        if (buildPhasesChanged ||
            pkgVersionsChanged ||
            enabledExperimentsChanged ||
            !isSameSdkVersion(
              previousAssetGraph.dartVersion,
              Platform.version,
            ) ||
            restartIsNeeded ||
            previousAssetGraph.kernelDigest != kernelFreshness.digest) {
          // Mark old outputs for deletion.
          filesToDelete.addAll(
            previousAssetGraph.outputsToDelete(buildPackages),
          );

          // Discard the invalid asset graph so that a new one will be created
          // from scratch.
          previousAssetGraph = null;
        }
      }
    }

    // If there was no previous asset graph or it was invalid, start by deleting
    // any invalid graph file and the generated output directory.
    if (previousAssetGraph == null) {
      filesToDelete.add(assetGraphId);
      foldersToDelete.add(generatedOutputDirectoryId);
    }

    final assetTracker = AssetTracker(
      readerWriter,
      buildPackages,
      buildConfigs,
    );
    final inputSources = await assetTracker.findInputSources();
    final cacheDirSources = await assetTracker.findCacheDirSources();

    AssetGraph? assetGraph;
    Map<AssetId, ChangeType>? updates;
    if (previousAssetGraph != null) {
      updates = await assetTracker.computeSourceUpdates(
        inputSources,
        cacheDirSources,
        previousAssetGraph,
      );
      assetGraph = previousAssetGraph.copyForNextBuild(buildPhases);

      if (restartIsNeeded) {
        // Mark old outputs for deletion.
        filesToDelete.addAll(previousAssetGraph.outputsToDelete(buildPackages));
        foldersToDelete.add(generatedOutputDirectoryId);

        // Discard the invalid asset graph so that a new one will be created
        // from scratch, and mark it for deletion so that the same will happen
        // if restarting.
        previousAssetGraph = null;
        filesToDelete.add(assetGraphId);

        // Discard state tied to the invalid asset graph.
        updates = null;
      }
    }

    if (assetGraph == null) {
      // Files marked for deletion are not inputs.
      inputSources.removeAll(filesToDelete);

      try {
        assetGraph = await AssetGraph.build(
          kernelDigest: kernelFreshness.digest,
          buildPhases,
          inputSources,
          buildPackages,
          readerWriter,
        );
      } on DuplicateAssetNodeException catch (e) {
        buildLog.error(e.toString());
        throw const CannotBuildException();
      }
      final conflictsInDeps =
          assetGraph.outputs
              .where((n) => !buildPackages.packagesInBuild.contains(n.package))
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
        assetGraph.outputs
            .where((n) => buildPackages.packagesInBuild.contains(n.package))
            .where(inputSources.contains)
            .toSet(),
      );
    }

    return BuildPlan(
      builderFactories: builderFactories,
      buildOptions: buildOptions,
      testingOverrides: testingOverrides,
      buildPackages: buildPackages,
      readerWriter: readerWriter,
      buildConfigs: buildConfigs,
      buildPhases: buildPhases,
      previousAssetGraph: previousAssetGraph,
      previousAssetGraphWasTaken: false,
      restartIsNeeded: restartIsNeeded,
      bootstrapper: bootstrapper,
      assetGraph: assetGraph,
      assetGraphWasTaken: false,
      updates: updates?.build(),
      filesToDelete: filesToDelete.toBuiltList(),
      foldersToDelete: foldersToDelete.toBuiltList(),
    );
  }

  BuildPlan copyWith({
    BuiltSet<BuildDirectory>? buildDirs,
    BuiltSet<BuildFilter>? buildFilters,
    ReaderWriter? readerWriter,
  }) => BuildPlan(
    builderFactories: builderFactories,
    buildOptions: buildOptions.copyWith(
      buildDirs: buildDirs,
      buildFilters: buildFilters,
    ),
    testingOverrides: testingOverrides,
    buildPackages: buildPackages,
    buildConfigs: buildConfigs,
    readerWriter: readerWriter ?? this.readerWriter,
    buildPhases: buildPhases,
    previousAssetGraph: _previousAssetGraph,
    previousAssetGraphWasTaken: _previousAssetGraphWasTaken,
    restartIsNeeded: restartIsNeeded,
    bootstrapper: bootstrapper,
    assetGraph: _assetGraph,
    assetGraphWasTaken: _assetGraphWasTaken,
    updates: updates,
    filesToDelete: filesToDelete,
    foldersToDelete: foldersToDelete,
  );

  /// Takes the loaded [AssetGraph], which may be `null` if none could be
  /// loaded or if it was invalid.
  ///
  /// Subsequent calls will throw. This is because [AssetGraph] is mutable, so
  /// the initial loaded state is only available once.
  AssetGraph? takePreviousAssetGraph() {
    if (_previousAssetGraphWasTaken) throw StateError('Already taken.');
    _previousAssetGraphWasTaken = true;
    return _previousAssetGraph;
  }

  /// Takes the [AssetGraph] for the build.
  ///
  /// Subsequent calls will throw. This is because [AssetGraph] is mutable, so
  /// the initial state is only available once.
  AssetGraph takeAssetGraph() {
    if (_assetGraphWasTaken) throw StateError('Already taken.');
    _assetGraphWasTaken = true;
    return _assetGraph;
  }

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

bool isSameSdkVersion(String? thisVersion, String? thatVersion) =>
    thisVersion?.split(' ').first == thatVersion?.split(' ').first;
