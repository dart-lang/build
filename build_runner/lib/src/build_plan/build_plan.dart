// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:build/build.dart';
import 'package:build/experiments.dart';
import 'package:built_collection/built_collection.dart';
import 'package:watcher/watcher.dart';

import '../bootstrap/bootstrapper.dart';
import '../bootstrap/build_process_state.dart';
import '../build/asset_graph/exceptions.dart';
import '../build/asset_graph/graph.dart';
import '../constants.dart';
import '../exceptions.dart';
import '../io/asset_tracker.dart';
import '../io/generated_asset_hider.dart';
import '../io/reader_writer.dart';
import '../logging/build_log.dart';
import 'build_directory.dart';
import 'build_filter.dart';
import 'build_options.dart';
import 'build_phases.dart';
import 'builder_factories.dart';
import 'package_graph.dart';
import 'target_graph.dart';
import 'testing_overrides.dart';

/// Options and derived configuration for a build.
class BuildPlan {
  final BuilderFactories builderFactories;
  final BuildOptions buildOptions;
  final TestingOverrides testingOverrides;

  final PackageGraph packageGraph;
  final ReaderWriter readerWriter;
  final TargetGraph targetGraph;
  final BuildPhases buildPhases;

  final AssetGraph? _previousAssetGraph;
  bool _previousAssetGraphWasTaken;

  final Bootstrapper bootstrapper;
  final AssetGraph _assetGraph;
  bool _assetGraphWasTaken;
  final BuiltMap<AssetId, ChangeType>? updates;

  final bool restartIsNeeded;
  final bool buildIsNeeded;

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
    required this.packageGraph,
    required this.readerWriter,
    required this.targetGraph,
    required this.buildPhases,
    required AssetGraph? previousAssetGraph,
    required bool previousAssetGraphWasTaken,
    required this.bootstrapper,
    required AssetGraph assetGraph,
    required bool assetGraphWasTaken,
    required this.updates,
    required this.filesToDelete,
    required this.foldersToDelete,
    required this.restartIsNeeded,
    required this.buildIsNeeded,
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
  /// If it's valid, the deserialized asset graph is available from
  /// [takePreviousAssetGraph].
  ///
  /// Files that should be deleted before restarting or building are accumulated
  /// in [filesToDelete] and [foldersToDelete]. Call [deleteFilesAndFolders] to
  /// delete them.
  static Future<BuildPlan> load({
    required BuilderFactories builderFactories,
    required BuildOptions buildOptions,
    required TestingOverrides testingOverrides,
  }) async {
    final packageGraph =
        testingOverrides.packageGraph ?? await PackageGraph.forThisPackage();

    final readerWriter =
        testingOverrides.readerWriter ?? ReaderWriter(packageGraph);

    final targetGraph = await TargetGraph.forPackageGraph(
      readerWriter: readerWriter,
      packageGraph: packageGraph,
      testingOverrides: testingOverrides,
      configKey: buildOptions.configKey,
    );

    var builderApplications =
        testingOverrides.builderApplications ??
        await builderFactories.createBuilderApplications(
          packageGraph: packageGraph,
          readerWriter: readerWriter,
        );

    var restartIsNeeded = false;
    if (builderApplications == null) {
      restartIsNeeded = true;
      buildLog.fullBuildBecause(FullBuildReason.incompatibleScript);
      builderApplications = BuiltList();
    }

    final buildPhases = await createBuildPhases(
      targetGraph,
      builderApplications,
      buildOptions.builderConfigOverrides,
      buildOptions.isReleaseBuild,
    );
    buildPhases.checkOutputLocations(packageGraph.root.name);
    if (buildPhases.inBuildPhases.isEmpty &&
        buildPhases.postBuildPhase.builderActions.isEmpty) {
      buildLog.warning('Nothing to build.');
    }

    // buildLog.doing('Reading the asset graph.');
    AssetGraph? previousAssetGraph;
    final filesToDelete = <AssetId>{};
    final foldersToDelete = <AssetId>{};

    final assetGraphId = AssetId(packageGraph.root.name, assetGraphPath);
    final generatedOutputDirectoryId = AssetId(
      packageGraph.root.name,
      generatedOutputDirectory,
    );

    var buildIsNeeded = false;
    if (await readerWriter.canRead(assetGraphId)) {
      previousAssetGraph = AssetGraph.deserialize(
        await readerWriter.readAsBytes(assetGraphId),
      );
      if (previousAssetGraph == null) {
        buildLog.fullBuildBecause(FullBuildReason.incompatibleAssetGraph);
        buildIsNeeded = true;
      } else {
        final buildPhasesChanged =
            buildPhases.digest != previousAssetGraph.buildPhasesDigest;
        final pkgVersionsChanged =
            previousAssetGraph.packageLanguageVersions !=
            packageGraph.languageVersions;
        final enabledExperimentsChanged =
            previousAssetGraph.enabledExperiments != enabledExperiments.build();
        if (buildPhasesChanged ||
            pkgVersionsChanged ||
            enabledExperimentsChanged ||
            !isSameSdkVersion(
              previousAssetGraph.dartVersion,
              Platform.version,
            )) {
          buildLog.fullBuildBecause(FullBuildReason.incompatibleBuild);
          buildIsNeeded = true;
          // Mark old outputs for deletion.
          filesToDelete.addAll(
            previousAssetGraph.outputsToDelete(packageGraph),
          );

          // Discard the invalid asset graph so that a new one will be created
          // from scratch, and delete it so that the same will happen if
          // restarting.
          filesToDelete.add(assetGraphId);
          previousAssetGraph = null;
        }
      }
    }

    if (buildProcessState.outputsAreFromStaleBuildScript &&
        previousAssetGraph != null) {
      // There is an asset graph it's from a stale script, use it only for
      // cleanup. Mark old outputs for deletion and discard the graph.
      filesToDelete.addAll(previousAssetGraph.outputsToDelete(packageGraph));
      previousAssetGraph = null;
      buildProcessState.outputsAreFromStaleBuildScript = false;
      buildIsNeeded = true;
    }

    // If there was no previous asset graph or it was invalid, start by deleting
    // the graph and the generated output directory.
    if (previousAssetGraph == null) {
      filesToDelete.add(assetGraphId);
      foldersToDelete.add(generatedOutputDirectoryId);
    }

    final assetTracker = AssetTracker(readerWriter, targetGraph);
    final inputSources = await assetTracker.findInputSources();
    final cacheDirSources = await assetTracker.findCacheDirSources();

    AssetGraph? assetGraph;
    BuiltMap<AssetId, ChangeType>? updates;
    if (previousAssetGraph != null) {
      // buildLog.doing('Checking for updates.');
      updates = await assetTracker.computeSourceUpdates(
        inputSources,
        cacheDirSources,
        previousAssetGraph,
      );
      assetGraph = previousAssetGraph.copyForNextBuild(buildPhases);
      if (updates.isNotEmpty) {
        buildIsNeeded = true;
      }

      if (assetGraph.previousBuildTriggersDigest !=
          targetGraph.buildTriggers.digest) {
        buildIsNeeded = true;
      }

      if (assetGraph.previousInBuildPhasesOptionsDigests !=
          assetGraph.inBuildPhasesOptionsDigests) {
        buildIsNeeded = true;
      }
    }

    if (assetGraph == null) {
      // buildLog.doing('Creating the asset graph.');

      // Files marked for deletion are not inputs.
      inputSources.removeAll(filesToDelete);

      try {
        assetGraph = await AssetGraph.build(
          buildPhases,
          inputSources,
          packageGraph,
          readerWriter,
        );
      } on DuplicateAssetNodeException catch (e) {
        buildLog.error(e.toString());
        throw const CannotBuildException();
      }
      final conflictsInDeps =
          assetGraph.outputs
              .where((n) => n.package != packageGraph.root.name)
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
            .where((n) => n.package == packageGraph.root.name)
            .where(inputSources.contains)
            .toSet(),
      );
    }

    return BuildPlan(
      builderFactories: builderFactories,
      buildOptions: buildOptions,
      testingOverrides: testingOverrides,
      packageGraph: packageGraph,
      readerWriter: readerWriter,
      targetGraph: targetGraph,
      buildPhases: buildPhases,
      previousAssetGraph: previousAssetGraph,
      previousAssetGraphWasTaken: false,
      bootstrapper: Bootstrapper(),
      assetGraph: assetGraph,
      assetGraphWasTaken: false,
      updates: updates,
      filesToDelete: filesToDelete.toBuiltList(),
      foldersToDelete: foldersToDelete.toBuiltList(),
      restartIsNeeded: restartIsNeeded,
      buildIsNeeded: buildIsNeeded,
    );
  }

  Future<BuildPlan> reload() => load(
    builderFactories: builderFactories,
    buildOptions: buildOptions,
    testingOverrides: testingOverrides,
  );

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
    packageGraph: packageGraph,
    targetGraph: targetGraph,
    readerWriter: readerWriter ?? this.readerWriter,
    buildPhases: buildPhases,
    previousAssetGraph: _previousAssetGraph,
    previousAssetGraphWasTaken: _previousAssetGraphWasTaken,
    bootstrapper: bootstrapper,
    assetGraph: _assetGraph,
    assetGraphWasTaken: _assetGraphWasTaken,
    updates: updates,
    filesToDelete: filesToDelete,
    foldersToDelete: foldersToDelete,
    restartIsNeeded: restartIsNeeded,
    buildIsNeeded: buildIsNeeded,
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
    buildLog.doing('Doing initial build cleanup.');

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
}

bool isSameSdkVersion(String? thisVersion, String? thatVersion) =>
    thisVersion?.split(' ').first == thatVersion?.split(' ').first;
