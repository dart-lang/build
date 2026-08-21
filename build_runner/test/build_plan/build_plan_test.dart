// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:build_config/build_config.dart' hide BuilderDefinition;
import 'package:build_runner/src/build/asset_content.dart';
import 'package:build_runner/src/build/build_state/asset_graph_json.dart';
import 'package:build_runner/src/build/build_state/build_state.dart';
import 'package:build_runner/src/build/build_state/build_step_result.dart';
import 'package:build_runner/src/build/library_cycle_graph/phased_asset_deps.dart';
import 'package:build_runner/src/build_plan/asset_file.dart';
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
          buildState: buildState.toSerializedBuildState(),
          phasedAssetDeps: PhasedAssetDeps(),
        ),
      );
    }

    test('reports updates', () async {
      final buildState = BuildState(
        buildStepPlan: buildPlan.buildStepPlan,
        sources: {assetId: null, assetId2: null},
      );

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

    group('incremental planning', () {
      test('deleted source is marked as deleted', () async {
        final buildState = BuildState(
          buildStepPlan: buildPlan.buildStepPlan,
          sources: {assetId: null},
        );
        buildState.updateSourceContent(
          assetId,
          AssetContent.digest(Digest([1])),
        );
        await writeBuildStateAndPlan(buildState, buildPlan);

        await readerWriter.delete(assetId);
        final newPlan = await loadPlan();
        expect(newPlan.buildInputs.deletedSources, contains(assetId));
        expect(newPlan.buildInputs.sources, isNot(contains(assetId)));
      });

      test('deleted output is marked as invalid output', () async {
        final buildState = BuildState(
          buildStepPlan: buildPlan.buildStepPlan,
          sources: {assetId: null},
        );
        await readerWriter.writeAsString(outputId, '// output');
        final stepId = buildPlan.buildStepPlan.stepForDeclaredOutput(outputId);
        buildState.updateBuildStepResult(
          stepId,
          BuildStepResult((b) {
            b.isHidden = false;
            b.outputs[outputId] = AssetContent.digest(Digest([1]));
          }),
        );
        buildState.updateSourceContent(
          assetId,
          AssetContent.digest(Digest([1])),
        );
        await writeBuildStateAndPlan(buildState, buildPlan);

        await readerWriter.delete(outputId);
        final newPlan = await loadPlan();
        expect(newPlan.buildInputs.invalidOutputs, contains(outputId));
      });

      test('new source file is marked as updated source', () async {
        final buildState = BuildState(
          buildStepPlan: buildPlan.buildStepPlan,
          sources: {assetId: null},
        );
        buildState.updateSourceContent(
          assetId,
          AssetContent.digest(Digest([1])),
        );
        await writeBuildStateAndPlan(buildState, buildPlan);

        final newSourceId = AssetId('a', 'lib/new_file.dart');
        await readerWriter.writeAsString(newSourceId, '// new');
        final newPlan = await loadPlan();
        expect(newPlan.buildInputs.updatedSources, contains(newSourceId));
        expect(newPlan.buildInputs.sources, contains(newSourceId));
      });

      test('stale cache file is marked as invalid output', () async {
        final buildState = BuildState(
          buildStepPlan: buildPlan.buildStepPlan,
          sources: {assetId: null},
        );
        buildState.updateSourceContent(
          assetId,
          AssetContent.digest(Digest([1])),
        );
        await writeBuildStateAndPlan(buildState, buildPlan);

        final staleCacheId = AssetId('a', 'lib/stale.dart.copy');
        await readerWriter.writeAsString(
          staleCacheId,
          '// stale',
          hidden: true,
        );
        final newPlan = await loadPlan();
        expect(newPlan.buildInputs.invalidOutputs, contains(staleCacheId));
      });

      test('modified source is marked as updated source', () async {
        final buildState = BuildState(
          buildStepPlan: buildPlan.buildStepPlan,
          sources: {assetId: null},
        );
        buildState.updateSourceContent(
          assetId,
          AssetContent.digest(Digest([1])),
        );
        await writeBuildStateAndPlan(buildState, buildPlan);

        await readerWriter.writeAsString(assetId, '// modified content');
        final newPlan = await loadPlan();
        expect(newPlan.buildInputs.updatedSources, contains(assetId));
      });

      test('modified output is marked as invalid output', () async {
        final buildState = BuildState(
          buildStepPlan: buildPlan.buildStepPlan,
          sources: {assetId: null},
        );
        await readerWriter.writeAsString(outputId, '// output');
        final stepId = buildPlan.buildStepPlan.stepForDeclaredOutput(outputId);
        buildState.updateBuildStepResult(
          stepId,
          BuildStepResult((b) {
            b.isHidden = false;
            b.outputs[outputId] = AssetContent.digest(Digest([1]));
          }),
        );
        buildState.updateSourceContent(
          assetId,
          AssetContent.digest(Digest([1])),
        );
        await writeBuildStateAndPlan(buildState, buildPlan);

        await readerWriter.writeAsString(outputId, '// modified output');
        final newPlan = await loadPlan();
        expect(newPlan.buildInputs.invalidOutputs, contains(outputId));
      });

      test(
        'displaced location where source conflicts with cache output marks '
        'conflicting source output to delete and keeps hidden output valid',
        () async {
          final buildState = BuildState(
            buildStepPlan: buildPlan.buildStepPlan,
            sources: {assetId: null, assetId2: null},
          );
          final hiddenOutputId = AssetId('a', 'lib/a.dart.copy');
          await readerWriter.writeAsString(
            hiddenOutputId,
            '// hidden output',
            hidden: true,
          );
          final stepId = buildPlan.buildStepPlan.stepForDeclaredOutput(
            hiddenOutputId,
          );
          buildState.updateBuildStepResult(
            stepId,
            BuildStepResult((b) {
              b.isHidden = true;
              b.outputs[hiddenOutputId] = AssetContent.string(
                '// hidden output',
              );
            }),
          );
          buildState.updateSourceContent(
            assetId,
            AssetContent.string('// a.dart'),
          );
          buildState.updateSourceContent(
            assetId2,
            AssetContent.string('// other'),
          );
          await writeBuildStateAndPlan(buildState, buildPlan);

          // Now user creates a source file with the same ID in the source tree
          await readerWriter.writeAsString(
            hiddenOutputId,
            '// conflicting source',
          );
          final newPlan = await loadPlan();
          expect(
            newPlan.conflictingOutputs,
            contains(AssetFile.source(hiddenOutputId)),
          );
          expect(
            newPlan.buildInputs.invalidOutputs,
            isNot(contains(hiddenOutputId)),
          );
          expect(newPlan.buildInputs.sources, isNot(contains(hiddenOutputId)));
        },
      );

      test('throws CannotBuildException if incremental build encounters '
          'conflicting outputs in dependencies', () async {
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
        final aId = AssetId('a', 'lib/a.dart');
        final depSourceId = AssetId('dep', 'lib/a.dart');
        await readerWriter.writeAsString(aId, '// a.dart');
        await readerWriter.writeAsString(depSourceId, '// dep a.dart');

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

        final initialPlan = await BuildPlan.load(
          await BuildSpec.load(
            builderFactories: builderFactories,
            buildOptions: buildOptions,
            testingOverrides: testingOverrides,
          ),
        );
        final buildState = BuildState(
          buildStepPlan: initialPlan.buildStepPlan,
          sources: {aId: null, depSourceId: null},
        );
        await readerWriter.writeAsBytes(
          AssetId('a', assetGraphJsonPath),
          AssetGraphJson.serialize(
            buildPlanDigest: initialPlan.buildSpec.buildPlanDigest,
            buildState: buildState.toSerializedBuildState(),
            phasedAssetDeps: PhasedAssetDeps(),
          ),
        );

        // Create a conflicting source file in the dependency.
        final depConflictId = AssetId('dep', 'lib/a.dart.copy');
        await readerWriter.writeAsString(depConflictId, '// conflict in dep');

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

      test('declared output that was never generated is not marked as invalid '
          'output when missing from disk', () async {
        final buildState = BuildState(
          buildStepPlan: buildPlan.buildStepPlan,
          sources: {assetId: null, assetId2: null},
        );
        buildState.updateSourceContent(
          assetId,
          AssetContent.string('// a.dart'),
        );
        buildState.updateSourceContent(
          assetId2,
          AssetContent.string('// other'),
        );
        await writeBuildStateAndPlan(buildState, buildPlan);

        final loadedPlan = await loadPlan();
        final updatedPlan = await loadedPlan.updateForFileChanges({
          AssetFile.source(outputId),
          AssetFile.cache(outputId),
        });
        expect(
          updatedPlan.buildInputs.invalidOutputs,
          isNot(contains(outputId)),
        );
        expect(
          updatedPlan.buildInputs.deletedSources,
          isNot(contains(outputId)),
        );
      });

      test(
        'declared output that was never generated is marked as invalid output '
        'and conflicting output when created in cache',
        () async {
          final buildState = BuildState(
            buildStepPlan: buildPlan.buildStepPlan,
            sources: {assetId: null, assetId2: null},
          );
          buildState.updateSourceContent(
            assetId,
            AssetContent.string('// a.dart'),
          );
          buildState.updateSourceContent(
            assetId2,
            AssetContent.string('// other'),
          );
          await writeBuildStateAndPlan(buildState, buildPlan);

          await readerWriter.writeAsString(
            outputId,
            '// unexpected cache file',
            hidden: true,
          );

          final loadedPlan = await loadPlan();
          expect(
            loadedPlan.conflictingOutputs,
            contains(AssetFile.cache(outputId)),
          );
          expect(loadedPlan.buildInputs.invalidOutputs, contains(outputId));
        },
      );

      test(
        'incremental build discovers an input and its output simultaneously',
        () async {
          final buildState = BuildState(
            buildStepPlan: buildPlan.buildStepPlan,
            sources: {assetId2: null},
          );
          buildState.updateSourceContent(
            assetId2,
            AssetContent.string('// other'),
          );
          await writeBuildStateAndPlan(buildState, buildPlan);

          // Write both a new input and a conflicting output simultaneously.
          final newInputId = AssetId('a', 'lib/new_input.dart');
          final newOutputId = AssetId('a', 'lib/new_input.dart.copy');
          await readerWriter.writeAsString(newInputId, '// new input');
          await readerWriter.writeAsString(
            newOutputId,
            '// conflicting output',
          );

          final loadedPlan = await loadPlan();

          // Input is marked as a source.
          expect(loadedPlan.buildInputs.sources, contains(newInputId));
          expect(loadedPlan.buildInputs.updatedSources, contains(newInputId));

          // Output is marked conflicting and not retained as a source.
          expect(
            loadedPlan.conflictingOutputs,
            contains(AssetFile.source(newOutputId)),
          );
          expect(loadedPlan.buildInputs.sources, isNot(contains(newOutputId)));

          // Output is not used as a primary input.
          expect(
            loadedPlan.buildStepPlan.declaredOutputsByPrimaryInput[newOutputId],
            isEmpty,
          );
        },
      );
    });
  });
}
