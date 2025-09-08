// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:build/build.dart';
import 'package:build/experiments.dart';
import 'package:built_collection/built_collection.dart';

import '../bootstrap/build_process_state.dart';
import '../build/asset_graph/graph.dart';
import '../constants.dart';
import '../io/reader_writer.dart';
import '../logging/build_log.dart';
import 'build_directory.dart';
import 'build_filter.dart';
import 'build_options.dart';
import 'build_phases.dart';
import 'builder_application.dart';
import 'package_graph.dart';
import 'target_graph.dart';
import 'testing_overrides.dart';

/// Options and derived configuration for a build.
class BuildPlan {
  final BuiltList<BuilderApplication> builders;
  final BuildOptions buildOptions;
  final TestingOverrides testingOverrides;

  final PackageGraph packageGraph;
  final ReaderWriter readerWriter;
  final TargetGraph targetGraph;
  final BuildPhases buildPhases;

  final AssetGraph? _assetGraph;
  bool _assetGraphWasTaken;
  final bool restartIsNeeded;

  /// Outputs from the previous build that should be deleted before restarting
  /// or before doing another build.
  ///
  /// It includes generated outputs of the previous build, which might not be
  /// findable later because they might not be outputs of the current build due
  /// to changes to configuration.
  ///
  /// If the old asset graph needs deleting prior to a restart it's also
  /// included here.
  ///
  /// Call[deletePreviousBuildOutputs] to delete them.
  final BuiltList<AssetId> previousBuildOutputs;

  BuildPlan({
    required this.builders,
    required this.buildOptions,
    required this.testingOverrides,
    required this.packageGraph,
    required this.readerWriter,
    required this.targetGraph,
    required this.buildPhases,
    required AssetGraph? assetGraph,
    required bool assetGraphWasTaken,
    required this.restartIsNeeded,
    required this.previousBuildOutputs,
  }) : _assetGraph = assetGraph,
       _assetGraphWasTaken = assetGraphWasTaken;

  /// Loads a build plan.
  ///
  /// Loads the package strucure and build configuration; prepares
  /// [readerWriter], deduces the [buildPhases] that will run, deserializes and
  /// checks the `AssetGraph`.
  ///
  /// If the asset graph indicates a restart is needed, [restartIsNeeded] will
  /// be set. Otherwise, if it's valid, the deserialized asset graph is
  /// available from [takeAssetGraph]. In any case, any outputs that it
  /// indicates should be deleted are loaded to [previousBuildOutputs].
  /// Call [deletePreviousBuildOutputs] to delete them.
  static Future<BuildPlan> load({
    required BuiltList<BuilderApplication> builders,
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

    final buildPhases = await createBuildPhases(
      targetGraph,
      builders,
      buildOptions.builderConfigOverrides,
      buildOptions.isReleaseBuild,
    );
    buildPhases.checkOutputLocations(packageGraph.root.name);
    if (buildPhases.inBuildPhases.isEmpty &&
        buildPhases.postBuildPhase.builderActions.isEmpty) {
      buildLog.warning('Nothing to build.');
    }

    buildLog.doing('Reading the asset graph.');
    AssetGraph? assetGraph;
    var restartIsNeeded = false;
    var previousBuildOutputs = BuiltList<AssetId>();
    final assetGraphId = AssetId(packageGraph.root.name, assetGraphPath);
    if (await readerWriter.canRead(assetGraphId)) {
      assetGraph = AssetGraph.deserialize(
        await readerWriter.readAsBytes(assetGraphId),
      );
      if (assetGraph == null) {
        buildLog.fullBuildBecause(FullBuildReason.incompatibleAssetGraph);
      } else {
        final buildPhasesChanged =
            buildPhases.digest != assetGraph.buildPhasesDigest;
        final pkgVersionsChanged =
            assetGraph.packageLanguageVersions != packageGraph.languageVersions;
        final enabledExperimentsChanged =
            assetGraph.enabledExperiments != enabledExperiments.build();
        if (buildPhasesChanged ||
            pkgVersionsChanged ||
            enabledExperimentsChanged ||
            !isSameSdkVersion(assetGraph.dartVersion, Platform.version)) {
          buildLog.fullBuildBecause(FullBuildReason.incompatibleBuild);

          // If running from snapshot, the changes mean the current snapshot
          // might be out of date and needs rebuilding. If not, the changes have
          // presumably already been picked up in the currently-running script.
          restartIsNeeded = _runningFromSnapshot;

          // In all cases, outputs of the previous build should be deleted as
          // they might not be findable within the current build.
          //
          // Only if restarting, the asset graph needs deleting before restart
          // to prevent looping restarts. If not restarting, it will be deleted
          // when the new asset graph is created.
          final outputsToDelete = ListBuilder<AssetId>();
          outputsToDelete.addAll(assetGraph.outputsToDelete(packageGraph));
          if (restartIsNeeded) outputsToDelete.add(assetGraphId);

          previousBuildOutputs = outputsToDelete.build();
          assetGraph = null;
        }
      }
    }

    return BuildPlan(
      builders: builders,
      buildOptions: buildOptions,
      testingOverrides: testingOverrides,
      packageGraph: packageGraph,
      readerWriter: readerWriter,
      targetGraph: targetGraph,
      buildPhases: buildPhases,
      assetGraph: assetGraph,
      assetGraphWasTaken: false,
      restartIsNeeded: restartIsNeeded,
      previousBuildOutputs: previousBuildOutputs,
    );
  }

  BuildPlan copyWith({
    BuiltSet<BuildDirectory>? buildDirs,
    BuiltSet<BuildFilter>? buildFilters,
    ReaderWriter? readerWriter,
  }) => BuildPlan(
    builders: builders,
    buildOptions: buildOptions.copyWith(
      buildDirs: buildDirs,
      buildFilters: buildFilters,
    ),
    testingOverrides: testingOverrides,
    packageGraph: packageGraph,
    targetGraph: targetGraph,
    readerWriter: readerWriter ?? this.readerWriter,
    buildPhases: buildPhases,
    assetGraph: _assetGraph,
    assetGraphWasTaken: _assetGraphWasTaken,
    restartIsNeeded: restartIsNeeded,
    previousBuildOutputs: previousBuildOutputs,
  );

  /// Takes the loaded [AssetGraph], which may be `null` if none could be
  /// loaded or if it was invalid.
  ///
  /// Subsequent calls will throw. This is because [AssetGraph] is mutable, so
  /// the initial loaded state is only available once.
  AssetGraph? takeAssetGraph() {
    if (_assetGraphWasTaken) throw StateError('Already taken.');
    _assetGraphWasTaken = true;
    return _assetGraph;
  }

  Future<void> deletePreviousBuildOutputs() async {
    for (final id in previousBuildOutputs) {
      if (await readerWriter.canRead(id)) {
        await readerWriter.delete(id);
      }
    }
  }
}

bool isSameSdkVersion(String? thisVersion, String? thatVersion) =>
    thisVersion?.split(' ').first == thatVersion?.split(' ').first;

bool get _runningFromSnapshot => !Platform.script.path.endsWith('.dart');
