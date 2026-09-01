// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:build/build.dart';
import 'package:build_config/build_config.dart'
    hide BuilderDefinition, PostProcessBuilderDefinition;
import 'package:build_runner/src/build/asset_content.dart';
import 'package:build_runner/src/build/build_state/asset_graph_json.dart';
import 'package:build_runner/src/build/build_state/build_state.dart';
import 'package:build_runner/src/build/build_state/build_step_result.dart';
import 'package:build_runner/src/build/build_state/post_process_build_step_id.dart';
import 'package:build_runner/src/build/build_state/post_process_build_step_result.dart';
import 'package:build_runner/src/build/library_cycle_graph/phased_asset_deps.dart';
import 'package:build_runner/src/build_plan/asset_file.dart';
import 'package:build_runner/src/build_plan/build_options.dart';
import 'package:build_runner/src/build_plan/build_package.dart';
import 'package:build_runner/src/build_plan/build_packages.dart';
import 'package:build_runner/src/build_plan/build_plan.dart';
import 'package:build_runner/src/build_plan/build_spec.dart';
import 'package:build_runner/src/build_plan/builder_definition.dart';
import 'package:build_runner/src/build_plan/builder_factories.dart';
import 'package:build_runner/src/build_plan/output_strategy.dart';

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

    Future<BuildPlan> loadPlan([
      TestingOverrides? overrides,
      BuilderFactories? factories,
    ]) async {
      return BuildPlan.load(
        await BuildSpec.load(
          builderFactories: factories ?? builderFactories,
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
          buildState: buildState.toIncrementalBuildState(),
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
      buildState.addBuildStepResult(
        step: stepId,
        result: BuildStepResult((b) {
          b.isHidden = false;
          b.outputs.add(outputId);
        }),
        contents: {
          outputId: AssetContent.string('// output', digest: Digest([])),
        },
      );
      // Give digests to inputs so they are monitored for modifications.
      buildState.updateSourceContent(assetId, AssetContent.bytes([]));
      buildState.updateSourceContent(assetId2, AssetContent.bytes([]));

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

    test('keep output strategy preserves manual changes to outputs '
        'with old digest', () async {
      buildOptions = BuildOptions.forTests(outputStrategy: OutputStrategy.keep);
      testingOverrides = testingOverrides.copyWith(
        builderDefinitions: [BuilderDefinition('', hideOutput: false)].build(),
      );
      buildPlan = await loadPlan();

      final buildState = BuildState(
        buildStepPlan: buildPlan.buildStepPlan,
        sources: {assetId: null, assetId2: null},
      );

      await readerWriter.writeAsString(outputId, '// output');
      final stepId = buildPlan.buildStepPlan.stepForDeclaredOutput(outputId);
      final initialDigest = md5.convert(utf8.encode('// output'));
      buildState.addBuildStepResult(
        step: stepId,
        result: BuildStepResult((b) {
          b.isHidden = false;
          b.outputs.add(outputId);
        }),
        contents: {
          outputId: AssetContent.bytes(
            utf8.encode('// output'),
            digest: initialDigest,
          ),
        },
      );
      buildState.updateSourceContent(
        assetId,
        AssetContent.bytes(utf8.encode('// a.dart')),
      );
      buildState.updateSourceContent(
        assetId2,
        AssetContent.bytes(utf8.encode('// other')),
      );

      await writeBuildStateAndPlan(buildState, buildPlan);

      await readerWriter.writeAsString(outputId, '// manually edited output');

      buildPlan = await loadPlan();

      expect(buildPlan.buildInputs.invalidOutputs, isEmpty);

      final outputContent =
          buildPlan.buildInputs.retainedOutputContents[outputId];
      expect(outputContent, isNotNull);
      expect(outputContent!.stringValue(), '// manually edited output');
      expect(outputContent.digest, initialDigest);
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
          AssetContent.string('// a.dart'),
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
        buildState.addBuildStepResult(
          step: stepId,
          result: BuildStepResult((b) {
            b.result = true;
            b.isHidden = false;
            b.outputs.add(outputId);
          }),
          contents: {outputId: AssetContent.string('// output')},
        );
        buildState.updateSourceContent(
          assetId,
          AssetContent.string('// a.dart'),
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
          AssetContent.string('// a.dart'),
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
          AssetContent.string('// a.dart'),
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
          AssetContent.string('// a.dart'),
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
        buildState.addBuildStepResult(
          step: stepId,
          result: BuildStepResult((b) {
            b.result = true;
            b.isHidden = false;
            b.outputs.add(outputId);
          }),
          contents: {outputId: AssetContent.string('// output')},
        );
        buildState.updateSourceContent(
          assetId,
          AssetContent.string('// a.dart'),
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
          buildState.addBuildStepResult(
            step: stepId,
            result: BuildStepResult((b) {
              b.result = true;
              b.isHidden = true;
              b.outputs.add(hiddenOutputId);
            }),
            contents: {hiddenOutputId: AssetContent.string('// hidden output')},
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

          // Now user creates a source file with the same ID in the source tree.
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
            buildState: buildState.toIncrementalBuildState(),
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
        'existing source is not marked as invalid output when unexpected cache '
        'file is created',
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

          // An unexpected cache file appears with the same ID as an existing
          // source.
          await readerWriter.writeAsString(
            assetId,
            '// unexpected cache file',
            hidden: true,
          );

          final loadedPlan = await loadPlan();
          expect(
            loadedPlan.conflictingOutputs,
            contains(AssetFile.cache(assetId)),
          );
          expect(
            loadedPlan.buildInputs.invalidOutputs,
            isNot(contains(assetId)),
          );
          expect(loadedPlan.buildInputs.sources, contains(assetId));
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

      test('newly discovered source with unexpected cache file does not mark '
          'source as invalid output', () async {
        final buildState = BuildState(
          buildStepPlan: buildPlan.buildStepPlan,
          sources: {assetId: null},
        );
        buildState.updateSourceContent(
          assetId,
          AssetContent.string('// a.dart'),
        );
        await writeBuildStateAndPlan(buildState, buildPlan);

        final newSourceId = AssetId('a', 'lib/new_source.dart');
        await readerWriter.writeAsString(newSourceId, '// new source');
        await readerWriter.writeAsString(
          newSourceId,
          '// unexpected cache',
          hidden: true,
        );

        final loadedPlan = await loadPlan();
        expect(
          loadedPlan.conflictingOutputs,
          contains(AssetFile.cache(newSourceId)),
        );
        expect(
          loadedPlan.buildInputs.invalidOutputs,
          isNot(contains(newSourceId)),
        );
        expect(loadedPlan.buildInputs.sources, contains(newSourceId));
        expect(loadedPlan.buildInputs.updatedSources, contains(newSourceId));
      });

      test('deleted input with hidden post process output does not mark new '
          'source as conflicting output', () async {
        final inputId = AssetId('a', 'lib/input.txt');
        final postOutputId = AssetId('a', 'lib/input.txt.post');
        await readerWriter.writeAsString(inputId, '// input');
        await readerWriter.writeAsString(postOutputId, '// post', hidden: true);

        final postBuilderDef = PostProcessBuilderDefinition('a:post');
        final postOverrides = TestingOverrides(
          builderDefinitions: [
            BuilderDefinition(
              '',
              appliesBuilders: ['a:post'],
              autoApply: AutoApply.rootPackage,
            ),
            postBuilderDef,
          ].build(),
          readerWriter: readerWriter,
          buildPackages: buildPackages,
          checkBuilderFreshness: false,
        );
        final postFactories = BuilderFactories(
          {
            '': [(_) => TestBuilder()],
          },
          postProcessBuilderFactories: {
            'a:post': (_) =>
                CopyingPostProcessBuilder(outputExtension: '.post'),
          },
        );

        final initialPlan = await loadPlan(postOverrides, postFactories);
        final postStepId = PostProcessBuildStepId(
          input: inputId,
          actionNumber: 0,
        );
        final buildState = BuildState(
          buildStepPlan: initialPlan.buildStepPlan,
          sources: {inputId: null, assetId: null},
        );
        buildState.addPostProcessBuildStepResult(
          step: postStepId,
          result: PostProcessBuildStepResult(
            hidden: true,
            outputs: [postOutputId],
          ),
          contents: {postOutputId: AssetContent.string('// post')},
        );
        buildState.updateSourceContent(
          inputId,
          AssetContent.string('// input'),
        );
        await writeBuildStateAndPlan(buildState, initialPlan);

        // Delete the input and create a source file at the old output path.
        await readerWriter.delete(inputId);
        await readerWriter.writeAsString(postOutputId, '// new source');

        final loadedPlan = await loadPlan(postOverrides, postFactories);
        expect(loadedPlan.buildInputs.sources, contains(postOutputId));
        expect(loadedPlan.buildInputs.updatedSources, contains(postOutputId));
        expect(
          loadedPlan.conflictingOutputs,
          isNot(contains(AssetFile.source(postOutputId))),
        );
        expect(
          loadedPlan.buildInputs.invalidOutputs,
          isNot(contains(postOutputId)),
        );
        expect(
          loadedPlan.buildInputs.retainedOutputContents.containsKey(
            postOutputId,
          ),
          isFalse,
        );
      });

      test('deleted input and deleted hidden post process output does not mark '
          'new source as invalid output', () async {
        final inputId = AssetId('a', 'lib/input.txt');
        final postOutputId = AssetId('a', 'lib/input.txt.post');
        await readerWriter.writeAsString(inputId, '// input');
        await readerWriter.writeAsString(postOutputId, '// post', hidden: true);

        final postBuilderDef = PostProcessBuilderDefinition('a:post');
        final postOverrides = TestingOverrides(
          builderDefinitions: [
            BuilderDefinition(
              '',
              appliesBuilders: ['a:post'],
              autoApply: AutoApply.rootPackage,
            ),
            postBuilderDef,
          ].build(),
          readerWriter: readerWriter,
          buildPackages: buildPackages,
          checkBuilderFreshness: false,
        );
        final postFactories = BuilderFactories(
          {
            '': [(_) => TestBuilder()],
          },
          postProcessBuilderFactories: {
            'a:post': (_) =>
                CopyingPostProcessBuilder(outputExtension: '.post'),
          },
        );

        final initialPlan = await loadPlan(postOverrides, postFactories);
        final postStepId = PostProcessBuildStepId(
          input: inputId,
          actionNumber: 0,
        );
        final buildState = BuildState(
          buildStepPlan: initialPlan.buildStepPlan,
          sources: {inputId: null, assetId: null},
        );
        buildState.addPostProcessBuildStepResult(
          step: postStepId,
          result: PostProcessBuildStepResult(
            hidden: true,
            outputs: [postOutputId],
          ),
          contents: {postOutputId: AssetContent.string('// post')},
        );
        buildState.updateSourceContent(
          inputId,
          AssetContent.string('// input'),
        );
        await writeBuildStateAndPlan(buildState, initialPlan);

        // Delete the input and the old hidden output.
        await readerWriter.delete(inputId);
        await readerWriter.delete(postOutputId, hidden: true);
        await readerWriter.writeAsString(postOutputId, '// new source');

        final loadedPlan = await loadPlan(postOverrides, postFactories);
        expect(loadedPlan.buildInputs.sources, contains(postOutputId));
        expect(loadedPlan.buildInputs.updatedSources, contains(postOutputId));
        expect(
          loadedPlan.conflictingOutputs,
          isNot(contains(AssetFile.source(postOutputId))),
        );
        expect(
          loadedPlan.buildInputs.invalidOutputs,
          isNot(contains(postOutputId)),
        );
      });

      test('existing input with hidden post process output marks new visible '
          'source as conflicting output', () async {
        final inputId = AssetId('a', 'lib/input.txt');
        final postOutputId = AssetId('a', 'lib/input.txt.post');
        await readerWriter.writeAsString(inputId, '// input');
        await readerWriter.writeAsString(postOutputId, '// post', hidden: true);

        final postBuilderDef = PostProcessBuilderDefinition('a:post');
        final postOverrides = TestingOverrides(
          builderDefinitions: [
            BuilderDefinition(
              '',
              appliesBuilders: ['a:post'],
              autoApply: AutoApply.rootPackage,
            ),
            postBuilderDef,
          ].build(),
          readerWriter: readerWriter,
          buildPackages: buildPackages,
          checkBuilderFreshness: false,
        );
        final postFactories = BuilderFactories(
          {
            '': [(_) => TestBuilder()],
          },
          postProcessBuilderFactories: {
            'a:post': (_) =>
                CopyingPostProcessBuilder(outputExtension: '.post'),
          },
        );

        final initialPlan = await loadPlan(postOverrides, postFactories);
        final postStepId = PostProcessBuildStepId(
          input: inputId,
          actionNumber: 0,
        );
        final buildState = BuildState(
          buildStepPlan: initialPlan.buildStepPlan,
          sources: {inputId: null, assetId: null},
        );
        buildState.addPostProcessBuildStepResult(
          step: postStepId,
          result: PostProcessBuildStepResult(
            hidden: true,
            outputs: [postOutputId],
          ),
          contents: {postOutputId: AssetContent.string('// post')},
        );
        buildState.updateSourceContent(
          inputId,
          AssetContent.string('// input'),
        );
        await writeBuildStateAndPlan(buildState, initialPlan);

        // Create a visible file at the post-process output location.
        await readerWriter.writeAsString(postOutputId, '// visible collision');

        final loadedPlan = await loadPlan(postOverrides, postFactories);
        expect(
          loadedPlan.conflictingOutputs,
          contains(AssetFile.source(postOutputId)),
        );
        expect(loadedPlan.buildInputs.sources, isNot(contains(postOutputId)));
        expect(
          loadedPlan.buildInputs.updatedSources,
          isNot(contains(postOutputId)),
        );
      });

      test('deleted input with transitive declared output replaced by visible '
          'source does not mark source as invalid output', () async {
        final stepId = buildPlan.buildStepPlan.stepForDeclaredOutput(outputId);
        final buildState = BuildState(
          buildStepPlan: buildPlan.buildStepPlan,
          sources: {assetId: null},
        );
        buildState.addBuildStepResult(
          step: stepId,
          result: BuildStepResult((b) {
            b.result = true;
            b.isHidden = true;
            b.outputs.add(outputId);
          }),
          contents: {outputId: AssetContent.string('// copy')},
        );
        buildState.updateSourceContent(
          assetId,
          AssetContent.string('// a.dart'),
        );
        await readerWriter.writeAsString(outputId, '// copy', hidden: true);
        await writeBuildStateAndPlan(buildState, buildPlan);

        // Delete the input and the hidden output, and add a visible source
        // file.
        await readerWriter.delete(assetId);
        await readerWriter.delete(outputId, hidden: true);
        await readerWriter.writeAsString(outputId, '// source content');

        final loadedPlan = await loadPlan();
        expect(loadedPlan.buildInputs.sources, contains(outputId));
        expect(
          loadedPlan.buildInputs.invalidOutputs,
          isNot(contains(outputId)),
        );
      });

      test(
        'outputs of deleted sources are evicted from retainedOutputContents',
        () async {
          final overrides = TestingOverrides(
            builderDefinitions: [
              BuilderDefinition('', hideOutput: false),
            ].build(),
            readerWriter: readerWriter,
            buildPackages: buildPackages,
            checkBuilderFreshness: false,
          );
          final initialPlan = await loadPlan(overrides);
          final buildState = BuildState(
            buildStepPlan: initialPlan.buildStepPlan,
            sources: {assetId: null, assetId2: null},
          );
          await readerWriter.writeAsString(outputId, '// copy');
          final stepId = initialPlan.buildStepPlan.stepForDeclaredOutput(
            outputId,
          );
          final initialDigest = md5.convert(utf8.encode('// copy'));
          buildState.addBuildStepResult(
            step: stepId,
            result: BuildStepResult((b) {
              b.result = true;
              b.isHidden = false;
              b.outputs.add(outputId);
            }),
            contents: {
              outputId: AssetContent.bytes(
                utf8.encode('// copy'),
                digest: initialDigest,
              ),
            },
          );
          buildState.updateSourceContent(
            assetId,
            AssetContent.bytes(utf8.encode('// a.dart')),
          );
          await writeBuildStateAndPlan(buildState, initialPlan);

          // Delete the input source.
          await readerWriter.delete(assetId);

          final loadedPlan = await loadPlan(overrides);
          expect(loadedPlan.buildInputs.deletedSources, contains(assetId));
          expect(loadedPlan.buildInputs.invalidOutputs, contains(outputId));
          expect(
            loadedPlan.buildInputs.retainedOutputContents.containsKey(outputId),
            isFalse,
          );
        },
      );

      test('withCompatiblePreviousBuild resets change tracking sets and '
          'cleanBuild', () async {
        final buildPlan = await loadPlan();
        final updatedPlan = buildPlan.rebuild(
          (b) => b
            ..buildInputs.cleanBuild = true
            ..buildInputs.deletedSources.add(assetId)
            ..buildInputs.updatedSources.add(assetId2)
            ..buildInputs.invalidOutputs.add(outputId),
        );

        final nextPlan = updatedPlan.withCompatiblePreviousBuild(
          previousBuildState: BuildState(
            buildStepPlan: buildPlan.buildStepPlan,
            sources: {assetId2: null},
          ).toFinishedBuildState(),
          previousPhasedAssetDeps: PhasedAssetDeps(),
        );

        expect(nextPlan.buildInputs.cleanBuild, isFalse);
        expect(nextPlan.buildInputs.deletedSources, isEmpty);
        expect(nextPlan.buildInputs.updatedSources, isEmpty);
        expect(nextPlan.buildInputs.invalidOutputs, isEmpty);
      });
    });
  });
}
