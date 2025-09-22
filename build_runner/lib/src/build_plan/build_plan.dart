// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:build/build.dart';
import 'package:build/experiments.dart';
import 'package:built_collection/built_collection.dart';
import 'package:watcher/watcher.dart';

import '../bootstrap/build_script_updates.dart';
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
  final bool restartIsNeeded;

  final BuildScriptUpdates? buildScriptUpdates;
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
    required this.packageGraph,
    required this.readerWriter,
    required this.targetGraph,
    required this.buildPhases,
    required AssetGraph? previousAssetGraph,
    required bool previousAssetGraphWasTaken,
    required this.restartIsNeeded,
    required this.buildScriptUpdates,
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
      builderApplications = BuiltList();
    }

    final buildPhases =
        testingOverrides.buildPhases ??
        await createBuildPhases(
          targetGraph,
          builderApplications,
          buildOptions.builderConfigOverrides,
          buildOptions.isReleaseBuild,
        );
    buildPhases.checkOutputLocations(packageGraph.root.name);
    if (buildPhases.inBuildPhases.isEmpty &&
        buildPhases.postBuildPhase.builderActions.isEmpty) {}

    AssetGraph? previousAssetGraph;
    final filesToDelete = <AssetId>{};
    final foldersToDelete = <AssetId>{};

    final assetGraphId = AssetId(packageGraph.root.name, assetGraphPath);
    final generatedOutputDirectoryId = AssetId(
      packageGraph.root.name,
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
          // Mark old outputs for deletion.
          filesToDelete.addAll(
            previousAssetGraph.outputsToDelete(packageGraph),
          );

          // If running from snapshot, the changes mean the current snapshot
          // might be out of date and needs rebuilding. If not, the changes have
          // presumably already been picked up in the currently-running script,
          // so continue to build a new asset graph from scrach.
          restartIsNeeded |= _runningFromSnapshot;

          // Discard the invalid asset graph so that a new one will be created
          // from scratch, and delete it so that the same will happen if
          // restarting.
          filesToDelete.add(assetGraphId);
          previousAssetGraph = null;
        }
      }
    }

    // If there was no previous asset graph or it was invalid, start by deleting
    // the generated output directory.
    if (previousAssetGraph == null) {
      foldersToDelete.add(generatedOutputDirectoryId);
    }

    final assetTracker = AssetTracker(readerWriter, targetGraph);
    final inputSources = await assetTracker.findInputSources();
    final cacheDirSources = await assetTracker.findCacheDirSources();
    final internalSources = await assetTracker.findInternalSources();

    AssetGraph? assetGraph;
    BuildScriptUpdates? buildScriptUpdates;
    Map<AssetId, ChangeType>? updates;
    if (previousAssetGraph != null) {
      updates = await assetTracker.computeSourceUpdates(
        inputSources,
        cacheDirSources,
        internalSources,
        previousAssetGraph,
      );
      buildScriptUpdates = await BuildScriptUpdates.create(
        readerWriter,
        packageGraph,
        previousAssetGraph,
        disabled: buildOptions.skipBuildScriptCheck,
      );

      final buildScriptUpdated =
          !buildOptions.skipBuildScriptCheck &&
          buildScriptUpdates.hasBeenUpdated(updates.keys.toSet());
      if (buildScriptUpdated) {
        // Mark old outputs for deletion.
        filesToDelete.addAll(previousAssetGraph.outputsToDelete(packageGraph));
        foldersToDelete.add(generatedOutputDirectoryId);

        // If running from snapshot, the changes mean the current snapshot
        // might be out of date and needs rebuilding. If not, the changes have
        // presumably already been picked up in the currently-running script,
        // so continue to build a new asset graph from scratch.
        restartIsNeeded |= _runningFromSnapshot;

        // Discard the invalid asset graph so that a new one will be created
        // from scratch, and mark it for deletion so that the same will happen
        // if restarting.
        previousAssetGraph = null;
        filesToDelete.add(assetGraphId);

        // Discard state tied to the invalid asset graph.
        buildScriptUpdates = null;
        updates = null;
      } else {
        assetGraph = previousAssetGraph.copyForNextBuild(buildPhases);
      }
    }

    if (assetGraph == null) {
      // Files marked for deletion are not inputs.
      inputSources.removeAll(filesToDelete);

      try {
        assetGraph = await AssetGraph.build(
          buildPhases,
          inputSources,
          internalSources,
          packageGraph,
          readerWriter,
        );
      } on DuplicateAssetNodeException catch (e) {
        buildLog.error(e.toString());
        throw const CannotBuildException();
      }
      buildScriptUpdates = await BuildScriptUpdates.create(
        readerWriter,
        packageGraph,
        assetGraph,
        disabled: buildOptions.skipBuildScriptCheck,
      );
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
      restartIsNeeded: restartIsNeeded,
      buildScriptUpdates: buildScriptUpdates,
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
    packageGraph: packageGraph,
    targetGraph: targetGraph,
    readerWriter: readerWriter ?? this.readerWriter,
    buildPhases: buildPhases,
    previousAssetGraph: _previousAssetGraph,
    previousAssetGraphWasTaken: _previousAssetGraphWasTaken,
    restartIsNeeded: restartIsNeeded,
    buildScriptUpdates: buildScriptUpdates,
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
  /// Works just like a new load of the build plan, but supresses the usual log
  /// output.
  ///
  /// The caller must call [deleteFilesAndFolders] on the result and check
  /// [restartIsNeeded].
  Future<BuildPlan> reload() => BuildPlan.load(
    builderFactories: builderFactories,
    buildOptions: buildOptions,
    testingOverrides: testingOverrides,
  );
}

bool isSameSdkVersion(String? thisVersion, String? thatVersion) =>
    thisVersion?.split(' ').first == thatVersion?.split(' ').first;

bool get _runningFromSnapshot => !Platform.script.path.endsWith('.dart');
