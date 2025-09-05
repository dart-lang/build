// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:built_collection/built_collection.dart';

import '../bootstrap/apply_builders.dart';
import '../io/reader_writer.dart';
import '../logging/build_log.dart';
import 'build_directory.dart';
import 'build_filter.dart';
import 'build_options.dart';
import 'build_phases.dart';
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

  BuildPlan({
    required this.builders,
    required this.buildOptions,
    required this.testingOverrides,
    required this.packageGraph,
    required this.readerWriter,
    required this.targetGraph,
    required this.buildPhases,
  });

  /// Loads a build plan.
  ///
  /// Loads the package strucure and build configuration; prepares
  /// [readerWriter] and deduces the [buildPhases] that will run.
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
    if (buildPhases.inBuildPhases.isEmpty &&
        buildPhases.postBuildPhase.builderActions.isEmpty) {
      buildLog.warning('Nothing to build.');
    }

    return BuildPlan(
      builders: builders,
      buildOptions: buildOptions,
      testingOverrides: testingOverrides,
      packageGraph: packageGraph,
      readerWriter: readerWriter,
      targetGraph: targetGraph,
      buildPhases: buildPhases,
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
  );
}
