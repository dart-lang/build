// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:build/build.dart';
import 'package:build_config/build_config.dart' hide BuilderDefinition;
import 'package:build_runner/src/asset_location.dart';
import 'package:build_runner/src/build/asset_content.dart';
import 'package:build_runner/src/build/build_state/asset_graph_json.dart';
import 'package:build_runner/src/build/build_state/build_state.dart';
import 'package:build_runner/src/build/build_state/build_step_result.dart';
import 'package:build_runner/src/build/library_cycle_graph/phased_asset_deps.dart';
import 'package:build_runner/src/build_plan/build_options.dart';
import 'package:build_runner/src/build_plan/build_package.dart';
import 'package:build_runner/src/build_plan/build_packages.dart';
import 'package:build_runner/src/build_plan/build_plan.dart';
import 'package:build_runner/src/build_plan/build_spec.dart';

import 'package:build_runner/src/build_plan/builder_definition.dart';
import 'package:build_runner/src/build_plan/builder_factories.dart';

import 'package:build_runner/src/build_plan/testing_overrides.dart';
import 'package:build_runner/src/constants.dart';
import 'package:build_runner/src/exceptions.dart';
import 'package:build_runner/src/io/reader_writer.dart';
import 'package:built_collection/built_collection.dart';
import 'package:crypto/crypto.dart';
import 'package:test/test.dart';

import '../common/common.dart';

void main() {
  setUpTestLogging();

  group('BuildPlan', () {
    final assetId = AssetId('a', 'lib/a.dart');
    final outputId = AssetId('a', 'lib/a.dart.copy');
    final assetId2 = AssetId('a', 'lib/an.other');
    final assetGraphJsonId = AssetId('a', assetGraphJsonPath);

    late BuildPackages buildPackages;
    late ReaderWriter readerWriter;
    late BuildOptions buildOptions;
    late BuilderFactories builderFactories;
    late TestingOverrides testingOverrides;
    late BuildPlan buildPlan;

    Future<BuildPlan> loadPlan([TestingOverrides? overrides]) async {
      return BuildPlan.load(
        await BuildSpec.load(
          builderFactories: builderFactories,
          buildOptions: buildOptions,
          testingOverrides: overrides ?? testingOverrides,
        ),
      );
    }

    setUp(() async {
      buildPackages = BuildPackages.singlePackageBuild('a', [
        BuildPackage.forTesting(name: 'a', watch: true, isOutput: true),
      ]);
      readerWriter = InternalTestReaderWriter(outputRootPackage: 'a');
      await readerWriter.writeAsString(assetId, '// a.dart');
      await readerWriter.writeAsString(assetId2, '// other');
      buildOptions = BuildOptions.forTests();
      builderFactories = BuilderFactories({
        '': [(_) => TestBuilder()],
        'b2': [(_) => TestBuilder(buildExtensions: appendExtension('.copy2'))],
      });
      testingOverrides = TestingOverrides(
        builderDefinitions: [BuilderDefinition('')].build(),
        readerWriter: readerWriter,
        buildPackages: buildPackages,
        checkBuilderFreshness: false,
      );
      buildPlan = await loadPlan();
    });

    Future<void> writeBuildStateAndPlan(
      BuildState buildState,
      BuildPlan buildPlan,
    ) async {
      await readerWriter.writeAsBytes(
        assetGraphJsonId,
        AssetGraphJson.serialize(
          buildPlanDigest: buildPlan.buildSpec.buildPlanDigest,
          buildState: buildState,
          phasedAssetDeps: PhasedAssetDeps(),
        ),
      );
    }

    test('reports updates', () async {
      final buildState = BuildState({assetId: null, assetId2: null});

      // Write an output and add it to the build state as if it was built.
      await readerWriter.writeAsString(outputId, '// output');
      final stepId = buildPlan.buildStepPlan.stepForDeclaredOutput(outputId);
      buildState.updateBuildStepResult(
        stepId,
        BuildStepResult((b) {
          b.isHidden = false;
          b.outputs[outputId] = AssetContent.digest(Digest([]));
        }),
      );
      // Give digests to inputs so they are monitored for modifications.
      buildState.updateSourceContent(assetId, AssetContent.digest(Digest([])));
      buildState.updateSourceContent(assetId2, AssetContent.digest(Digest([])));

      await writeBuildStateAndPlan(buildState, buildPlan);

      // Remove source.
      await readerWriter.delete(assetId);
      // Change source.
      await readerWriter.writeAsString(assetId2, 'changed');
      // Add source.
      final assetId3 = AssetId('a', 'lib/new.dart');
      await readerWriter.writeAsString(assetId3, '');

      // Remove generated.
      await readerWriter.delete(outputId);

      buildPlan = await loadPlan();

      expect(
        {
          ...buildPlan.buildInputs.updatedSources,
          ...buildPlan.buildInputs.deletedSources,
          ...buildPlan.buildInputs.invalidOutputs,
        },
        {assetId, assetId2, assetId3, outputId},
      );
    });

    test('applies target glob from build config', () async {
      final buildConfig1 = runInBuildConfigZone(
        () {
          return BuildConfig(
            packageName: 'a',
            buildTargets: {
              'a|a': BuildTarget(
                sources: const InputSet(include: ['**/*.dart']),
              ),
            },
          );
        },
        'a',
        [],
      );
      final buildPlan1 = await BuildPlan.load(
        await BuildSpec.load(
          builderFactories: builderFactories,
          buildOptions: buildOptions,
          testingOverrides: testingOverrides.copyWith(
            buildConfig: {'a': buildConfig1}.build(),
          ),
        ),
      );
      // Matches the only `*.dart` source.
      expect(buildPlan1.buildInputs.sources.toSet(), <AssetId>{assetId});

      // Same again but now glob `*.other`.
      final buildConfig2 = runInBuildConfigZone(
        () {
          return BuildConfig(
            packageName: 'a',
            buildTargets: {
              'a|a': BuildTarget(
                sources: const InputSet(include: ['**/*.other']),
              ),
            },
          );
        },
        'a',
        [],
      );
      final buildPlan2 = await BuildPlan.load(
        await BuildSpec.load(
          builderFactories: builderFactories,
          buildOptions: buildOptions,
          testingOverrides: testingOverrides.copyWith(
            buildConfig: {'a': buildConfig2}.build(),
          ),
        ),
      );
      // Matches the only `*.other` source.
      expect(buildPlan2.buildInputs.sources.toSet(), <AssetId>{assetId2});
    });

    test('throws CannotBuildException if there are conflicting outputs '
        'in dependencies', () async {
      final buildPackages = BuildPackages.singlePackageBuild('a', [
        BuildPackage.forTesting(
          name: 'a',
          watch: true,
          isOutput: true,
          dependencies: ['dep'],
        ),
        BuildPackage.forTesting(name: 'dep', watch: true, isOutput: false),
      ]);
      final readerWriter = InternalTestReaderWriter(outputRootPackage: 'a');
      await readerWriter.writeAsString(AssetId('a', 'lib/a.dart'), '// a.dart');
      await readerWriter.writeAsString(
        AssetId('dep', 'lib/a.dart'),
        '// dep a.dart',
      );

      final conflictId = AssetId('dep', 'lib/a.dart.copy');
      await readerWriter.writeAsString(conflictId, '// conflict');

      final testingOverrides = TestingOverrides(
        builderDefinitions: [
          BuilderDefinition(
            '',
            hideOutput: true,
            autoApply: AutoApply.allPackages,
          ),
        ].build(),
        readerWriter: readerWriter,
        buildPackages: buildPackages,
        checkBuilderFreshness: false,
      );

      expect(
        () async => await BuildPlan.load(
          await BuildSpec.load(
            builderFactories: builderFactories,
            buildOptions: buildOptions,
            testingOverrides: testingOverrides,
          ),
        ),
        throwsA(const TypeMatcher<CannotBuildException>()),
      );
    });

    test('incremental build does not classify new files that match declared '
        'outputs as inputs', () async {
      final buildState = BuildState({assetId: null});
      await writeBuildStateAndPlan(buildState, buildPlan);

      final newSourceId = AssetId('a', 'lib/b.dart');
      final matchingOutputId = AssetId('a', 'lib/b.dart.copy');
      await readerWriter.writeAsString(newSourceId, '// b.dart');
      await readerWriter.writeAsString(matchingOutputId, '');

      buildPlan = await loadPlan();

      expect(buildPlan.buildInputs.sources.toSet(), contains(newSourceId));
      expect(
        buildPlan.buildInputs.sources.toSet(),
        isNot(contains(matchingOutputId)),
      );
      expect(
        buildPlan.conflictingOutputs.map((c) => c.id),
        contains(matchingOutputId),
      );
    });

    test('incremental build handles hidden unexpected outputs in dependency '
        'without throwing', () async {
      final buildPackagesWithDep = BuildPackages.singlePackageBuild('a', [
        BuildPackage.forTesting(
          name: 'a',
          watch: true,
          isOutput: true,
          dependencies: const ['dep'],
        ),
        BuildPackage.forTesting(name: 'dep', watch: false, isOutput: false),
      ]);
      final depBuildConfig = BuildConfig.parse('dep', const [], '''
targets:
  \$default:
    auto_apply_builders: true
''');
      final initialTestingOverrides = TestingOverrides(
        builderDefinitions: [
          BuilderDefinition(
            '',
            hideOutput: true,
            autoApply: AutoApply.allPackages,
          ),
        ].build(),
        buildConfig: {'dep': depBuildConfig}.build(),
        readerWriter: readerWriter,
        buildPackages: buildPackagesWithDep,
        checkBuilderFreshness: false,
      );
      final depSourceId = AssetId('dep', 'lib/a.dart');
      await readerWriter.writeAsString(depSourceId, '// dep a.dart');
      final initialPlan = await loadPlan(initialTestingOverrides);
      final buildState = BuildState({assetId: null, depSourceId: null});
      await writeBuildStateAndPlan(buildState, initialPlan);

      final depOutputId = AssetId('dep', 'lib/a.dart.copy');
      await readerWriter.writeAsString(depOutputId, '', hidden: true);

      buildPlan = await loadPlan(initialTestingOverrides);
      expect(
        buildPlan.conflictingOutputs.map((c) => c.id),
        contains(depOutputId),
      );
      expect(
        buildPlan.conflictingOutputs
            .firstWhere((c) => c.id == depOutputId)
            .hidden,
        isTrue,
      );
    });

    test(
      'tracks both source and cache conflicting files for the same output',
      () async {
        final buildState = BuildState({assetId: null});
        await writeBuildStateAndPlan(buildState, buildPlan);

        final newSourceId = AssetId('a', 'lib/b.dart');
        final matchingOutputId = AssetId('a', 'lib/b.dart.copy');
        await readerWriter.writeAsString(newSourceId, '// b.dart');
        // Write visible conflict in source tree.
        await readerWriter.writeAsString(matchingOutputId, '// visible');
        // Write hidden conflict in cache.
        await readerWriter.writeAsString(
          matchingOutputId,
          '// hidden',
          hidden: true,
        );

        buildPlan = await loadPlan();

        expect(buildPlan.buildInputs.sources.toSet(), contains(newSourceId));
        expect(
          buildPlan.buildInputs.sources.toSet(),
          isNot(contains(matchingOutputId)),
        );
        final conflicts = buildPlan.conflictingOutputs
            .where((c) => c.id == matchingOutputId)
            .toSet();
        expect(
          conflicts,
          equals({
            AssetLocation.source(matchingOutputId),
            AssetLocation.cache(matchingOutputId),
          }),
        );
      },
    );

    test('clean build includes hidden conflicting files from cache', () async {
      final conflictId = AssetId('a', 'lib/a.dart.copy');
      await readerWriter.writeAsString(conflictId, '// hidden', hidden: true);

      buildPlan = await loadPlan();

      expect(
        buildPlan.conflictingOutputs,
        contains(AssetLocation.cache(conflictId)),
      );
    });

    test(
      'conflict hidden reflects file location, not builder output location',
      () async {
        final buildState = BuildState({assetId: null});
        await writeBuildStateAndPlan(buildState, buildPlan);

        final newSourceId = AssetId('a', 'lib/b.dart');
        final matchingOutputId = AssetId('a', 'lib/b.dart.copy');
        await readerWriter.writeAsString(newSourceId, '// b.dart');
        // Builder default is visible output, but the conflicting file is in
        // cache.
        await readerWriter.writeAsString(
          matchingOutputId,
          '// hidden',
          hidden: true,
        );

        buildPlan = await loadPlan();

        expect(
          buildPlan.conflictingOutputs,
          contains(AssetLocation.cache(matchingOutputId)),
        );
      },
    );

    test('previous hidden actual output plus new visible conflict', () async {
      final testingOverrides = TestingOverrides(
        builderDefinitions: [
          BuilderDefinition(
            '',
            hideOutput: true,
            autoApply: AutoApply.allPackages,
          ),
        ].build(),
        readerWriter: readerWriter,
        buildPackages: buildPackages,
        checkBuilderFreshness: false,
      );
      final initialPlan = await loadPlan(testingOverrides);
      final buildState = BuildState({assetId: null});

      // Write hidden output and add to build state.
      await readerWriter.writeAsString(outputId, '// hidden', hidden: true);
      final stepId = initialPlan.buildStepPlan.stepForDeclaredOutput(outputId);
      buildState.updateBuildStepResult(
        stepId,
        BuildStepResult((b) {
          b.isHidden = true;
          b.outputs[outputId] = AssetContent.digest(Digest([]));
        }),
      );
      await writeBuildStateAndPlan(buildState, initialPlan);

      // Now create new visible conflict in source tree.
      await readerWriter.writeAsString(outputId, '// visible conflict');

      buildPlan = await loadPlan(testingOverrides);
      expect(
        buildPlan.conflictingOutputs,
        contains(AssetLocation.source(outputId)),
      );
    });

    test('previous visible actual output plus new hidden conflict', () async {
      final testingOverrides = TestingOverrides(
        builderDefinitions: [
          BuilderDefinition(
            '',
            hideOutput: false,
            autoApply: AutoApply.allPackages,
          ),
        ].build(),
        readerWriter: readerWriter,
        buildPackages: buildPackages,
        checkBuilderFreshness: false,
      );
      final initialPlan = await loadPlan(testingOverrides);
      final buildState = BuildState({assetId: null});

      // Write visible output and add to build state.
      await readerWriter.writeAsString(outputId, '// visible');
      final stepId = initialPlan.buildStepPlan.stepForDeclaredOutput(outputId);
      buildState.updateBuildStepResult(
        stepId,
        BuildStepResult((b) {
          b.isHidden = false;
          b.outputs[outputId] = AssetContent.digest(Digest([]));
        }),
      );
      await writeBuildStateAndPlan(buildState, initialPlan);

      // Now create new hidden conflict in cache.
      await readerWriter.writeAsString(
        outputId,
        '// hidden conflict',
        hidden: true,
      );

      buildPlan = await loadPlan(testingOverrides);
      expect(
        buildPlan.conflictingOutputs,
        contains(AssetLocation.cache(outputId)),
      );
    });

    test(
      'previous visible source and unrelated cache file with same AssetId',
      () async {
        final buildState = BuildState({
          assetId: AssetContent.bytes(utf8.encode('// a.dart')),
          assetId2: AssetContent.bytes(utf8.encode('// other')),
        });
        await writeBuildStateAndPlan(buildState, buildPlan);

        // Write an unrelated cache file with the same AssetId but different
        // content.
        await readerWriter.writeAsString(
          assetId,
          '// cache content',
          hidden: true,
        );

        buildPlan = await loadPlan();

        expect(buildPlan.buildInputs.sources, contains(assetId));
        expect(buildPlan.buildInputs.invalidOutputs, isEmpty);
        expect(buildPlan.buildInputs.updatedSources, isEmpty);
        expect(buildPlan.buildInputs.deletedSources, isEmpty);
      },
    );
  });

  group('updateForFileChanges', () {
    final assetId = AssetId('a', 'lib/a.dart');
    final outputId = AssetId('a', 'lib/a.dart.copy');
    final assetId2 = AssetId('a', 'lib/an.other');

    late BuildPackages buildPackages;
    late ReaderWriter readerWriter;
    late BuildOptions buildOptions;
    late BuilderFactories builderFactories;
    late TestingOverrides testingOverrides;
    late BuildPlan buildPlan;

    Future<BuildPlan> loadPlan([TestingOverrides? overrides]) async {
      return BuildPlan.load(
        await BuildSpec.load(
          builderFactories: builderFactories,
          buildOptions: buildOptions,
          testingOverrides: overrides ?? testingOverrides,
        ),
      );
    }

    setUp(() async {
      buildPackages = BuildPackages.singlePackageBuild('a', [
        BuildPackage.forTesting(name: 'a', watch: true, isOutput: true),
      ]);
      readerWriter = InternalTestReaderWriter(outputRootPackage: 'a');
      await readerWriter.writeAsString(assetId, '// a.dart');
      await readerWriter.writeAsString(assetId2, '// other');
      buildOptions = BuildOptions.forTests();
      builderFactories = BuilderFactories({
        '': [(_) => TestBuilder()],
        'b2': [(_) => TestBuilder(buildExtensions: appendExtension('.copy2'))],
      });
      testingOverrides = TestingOverrides(
        builderDefinitions: [
          BuilderDefinition('', autoApply: AutoApply.allPackages),
          BuilderDefinition('b2', autoApply: AutoApply.allPackages),
        ].build(),
        readerWriter: readerWriter,
        buildPackages: buildPackages,
        checkBuilderFreshness: false,
      );
      buildPlan = await loadPlan();
    });

    Future<void> writeBuildStateAndPlan(
      BuildState buildState,
      BuildPlan buildPlan,
    ) async {
      final assetGraphJsonId = AssetId('a', assetGraphJsonPath);
      await readerWriter.writeAsBytes(
        assetGraphJsonId,
        AssetGraphJson.serialize(
          buildPlanDigest: buildPlan.buildSpec.buildPlanDigest,
          buildState: buildState,
          phasedAssetDeps: PhasedAssetDeps(),
        ),
      );
    }

    test('new visible conflict', () async {
      final buildState = BuildState({
        assetId: AssetContent.bytes(utf8.encode('// a.dart')),
        assetId2: AssetContent.bytes(utf8.encode('// other')),
      });
      await writeBuildStateAndPlan(buildState, buildPlan);
      final initialPlan = await loadPlan();

      // Write a new visible conflicting file on disk.
      await readerWriter.writeAsString(outputId, '// visible conflict');

      final updatedPlan = await initialPlan.updateForFileChanges({
        AssetLocation.source(outputId),
      });

      expect(
        updatedPlan.conflictingOutputs,
        contains(AssetLocation.source(outputId)),
      );
    });

    test('new hidden conflict', () async {
      final buildState = BuildState({
        assetId: AssetContent.bytes(utf8.encode('// a.dart')),
        assetId2: AssetContent.bytes(utf8.encode('// other')),
      });
      await writeBuildStateAndPlan(buildState, buildPlan);
      final initialPlan = await loadPlan();

      // Write a new hidden conflicting file in cache.
      await readerWriter.writeAsString(
        outputId,
        '// hidden conflict',
        hidden: true,
      );

      final updatedPlan = await initialPlan.updateForFileChanges({
        AssetLocation.cache(outputId),
      });

      expect(
        updatedPlan.conflictingOutputs,
        contains(AssetLocation.cache(outputId)),
      );
    });

    test('modified previous hidden output', () async {
      final testingOverrides = TestingOverrides(
        builderDefinitions: [
          BuilderDefinition(
            '',
            hideOutput: true,
            autoApply: AutoApply.allPackages,
          ),
        ].build(),
        readerWriter: readerWriter,
        buildPackages: buildPackages,
        checkBuilderFreshness: false,
      );
      final initialPlan = await loadPlan(testingOverrides);
      final buildState = BuildState({
        assetId: AssetContent.bytes(utf8.encode('// a.dart')),
        assetId2: AssetContent.bytes(utf8.encode('// other')),
      });

      // Write hidden output and record in build state.
      await readerWriter.writeAsString(outputId, '// hidden', hidden: true);
      final stepId = initialPlan.buildStepPlan.stepForDeclaredOutput(outputId);
      buildState.updateBuildStepResult(
        stepId,
        BuildStepResult((b) {
          b.isHidden = true;
          b.outputs[outputId] = AssetContent.bytes(utf8.encode('// hidden'));
        }),
      );
      await writeBuildStateAndPlan(buildState, initialPlan);
      final loadedPlan = await loadPlan(testingOverrides);

      // Now modify the hidden output on disk.
      await readerWriter.writeAsString(
        outputId,
        '// hidden modified',
        hidden: true,
      );

      final updatedPlan = await loadedPlan.updateForFileChanges({
        AssetLocation.cache(outputId),
      });

      expect(updatedPlan.buildInputs.invalidOutputs, contains(outputId));
    });

    test('deleted previous hidden output', () async {
      final testingOverrides = TestingOverrides(
        builderDefinitions: [
          BuilderDefinition(
            '',
            hideOutput: true,
            autoApply: AutoApply.allPackages,
          ),
        ].build(),
        readerWriter: readerWriter,
        buildPackages: buildPackages,
        checkBuilderFreshness: false,
      );
      final initialPlan = await loadPlan(testingOverrides);
      final buildState = BuildState({
        assetId: AssetContent.bytes(utf8.encode('// a.dart')),
        assetId2: AssetContent.bytes(utf8.encode('// other')),
      });

      // Write hidden output and record in build state.
      await readerWriter.writeAsString(outputId, '// hidden', hidden: true);
      final stepId = initialPlan.buildStepPlan.stepForDeclaredOutput(outputId);
      buildState.updateBuildStepResult(
        stepId,
        BuildStepResult((b) {
          b.isHidden = true;
          b.outputs[outputId] = AssetContent.bytes(utf8.encode('// hidden'));
        }),
      );
      await writeBuildStateAndPlan(buildState, initialPlan);
      final loadedPlan = await loadPlan(testingOverrides);

      // Now delete the hidden output from disk.
      await readerWriter.delete(outputId, hidden: true);

      final updatedPlan = await loadedPlan.updateForFileChanges({
        AssetLocation.cache(outputId),
      });

      expect(updatedPlan.buildInputs.invalidOutputs, contains(outputId));
    });
  });
}
