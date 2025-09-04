// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:built_collection/built_collection.dart';

import 'asset/reader_writer.dart';
import 'asset/writer.dart';
import 'commands/build_filter.dart';
import 'commands/build_options.dart';
import 'generate/build_directory.dart';
import 'generate/build_phases.dart';
import 'logging/build_log.dart';
import 'options/testing_overrides.dart';
import 'package_graph/apply_builders.dart';
import 'package_graph/package_graph.dart';
import 'package_graph/target_graph.dart';

/// Options and derived configuration for a build.
class BuildPlan {
  final BuiltList<BuilderApplication> builders;
  final BuildOptions buildOptions;
  final TestingOverrides testingOverrides;

  final PackageGraph packageGraph;
  final AssetReader reader;
  final RunnerAssetWriter writer;
  final TargetGraph targetGraph;
  final BuildPhases buildPhases;

  BuildPlan({
    required this.builders,
    required this.buildOptions,
    required this.testingOverrides,
    required this.packageGraph,
    required this.reader,
    required this.writer,
    required this.targetGraph,
    required this.buildPhases,
  });

  /// Loads a build plan.
  ///
  /// Loads the package strucure and build configuration; prepares [reader]
  /// and [writer] and deduces the [buildPhases] that will run.
  static Future<BuildPlan> load({
    required BuiltList<BuilderApplication> builders,
    required BuildOptions buildOptions,
    required TestingOverrides testingOverrides,
  }) async {
    final packageGraph =
        testingOverrides.packageGraph ?? await PackageGraph.forThisPackage();

    var reader = testingOverrides.reader;
    var writer = testingOverrides.writer;

    if (reader == null || writer == null) {
      final readerWriter = ReaderWriter(packageGraph);
      reader ??= readerWriter;
      writer ??= readerWriter;
    }

    final targetGraph = await TargetGraph.forPackageGraph(
      reader: reader,
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
      reader: reader,
      writer: writer,
      targetGraph: targetGraph,
      buildPhases: buildPhases,
    );
  }

  BuildPlan copyWith({
    BuiltSet<BuildDirectory>? buildDirs,
    BuiltSet<BuildFilter>? buildFilters,
    AssetReader? reader,
    RunnerAssetWriter? writer,
  }) => BuildPlan(
    builders: builders,
    buildOptions: buildOptions.copyWith(
      buildDirs: buildDirs,
      buildFilters: buildFilters,
    ),
    testingOverrides: testingOverrides,
    packageGraph: packageGraph,
    targetGraph: targetGraph,
    reader: reader ?? this.reader,
    writer: writer ?? this.writer,
    buildPhases: buildPhases,
  );
}
