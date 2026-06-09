// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';

import '../bootstrap/bootstrapper.dart';
import '../bootstrap/depfile.dart';

import '../io/filesystem_cache.dart';
import '../io/reader_writer.dart';
import 'build_configs.dart';
import 'build_options.dart';
import 'build_packages.dart';
import 'build_phase_creator.dart';
import 'build_phases.dart';
import 'build_spec_digest.dart';
import 'builder_definition.dart';
import 'builder_factories.dart';
import 'testing_overrides.dart';

part 'build_spec.g.dart';

/// The build options, configuration and setup that stay the same across a
/// series of incremental builds.
abstract class BuildSpec implements Built<BuildSpec, BuildSpecBuilder> {
  BuildSpecDigest get buildPlanDigest;
  BuilderFactories get builderFactories;
  BuildOptions get buildOptions;
  TestingOverrides get testingOverrides;
  Bootstrapper get bootstrapper;
  BuildPackages get buildPackages;
  BuildConfigs get buildConfigs;
  BuildPhases get buildPhases;
  ReaderWriter get readerWriter;
  bool get restartIsNeeded;

  BuildSpec._();
  factory BuildSpec([void Function(BuildSpecBuilder) updates]) = _$BuildSpec;

  /// Loads the package structure and build configuration.
  ///
  /// Determines whether [restartIsNeeded] to pick up new builder factories or
  /// changes to `build_runner` code.
  ///
  /// Set [recentlyBootstrapped] to false to do checks that are also done during
  /// bootstrapping.
  static Future<BuildSpec> load({
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

    final buildPlanDigest = BuildSpecDigest(
      compileDigest: compileFreshness.digest,
      buildConfigs: buildConfigs,
      buildPhases: buildPhases,
      buildPackages: buildPackages,
    );

    return BuildSpec(
      (b) => b
        ..buildPlanDigest.replace(buildPlanDigest)
        ..builderFactories = builderFactories
        ..buildOptions = buildOptions
        ..testingOverrides = testingOverrides
        ..bootstrapper = bootstrapper
        ..buildPackages = buildPackages
        ..buildConfigs = buildConfigs
        ..buildPhases = buildPhases
        ..readerWriter = readerWriter
        ..restartIsNeeded = restartIsNeeded,
    );
  }
}
