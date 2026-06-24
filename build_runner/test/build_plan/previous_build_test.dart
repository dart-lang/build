// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:build/build.dart';
import 'package:build/experiments.dart';
import 'package:build_config/build_config.dart' hide BuilderDefinition;
import 'package:build_runner/src/build/asset_content.dart';
import 'package:build_runner/src/build/build_state/asset_graph_json.dart';
import 'package:build_runner/src/build/build_state/build_state.dart';
import 'package:build_runner/src/build/build_state/build_step_result.dart';
import 'package:build_runner/src/build/library_cycle_graph/phased_asset_deps.dart';
import 'package:build_runner/src/build_plan/build_options.dart';
import 'package:build_runner/src/build_plan/build_package.dart';
import 'package:build_runner/src/build_plan/build_packages.dart';
import 'package:build_runner/src/build_plan/build_spec.dart';
import 'package:build_runner/src/build_plan/build_spec_digest.dart';
import 'package:build_runner/src/build_plan/build_step_plan.dart';
import 'package:build_runner/src/build_plan/builder_definition.dart';
import 'package:build_runner/src/build_plan/builder_factories.dart';
import 'package:build_runner/src/build_plan/previous_build.dart';
import 'package:build_runner/src/build_plan/testing_overrides.dart';
import 'package:build_runner/src/constants.dart';
import 'package:build_runner/src/io/reader_writer.dart';
import 'package:built_collection/built_collection.dart';
import 'package:crypto/crypto.dart';
import 'package:test/test.dart';

import '../common/common.dart';

void main() {
  setUpTestLogging();

  group('PreviousBuild', () {
    final assetId = AssetId('a', 'lib/a.dart');
    final outputId = AssetId('a', 'lib/a.dart.copy');
    final assetId2 = AssetId('a', 'lib/an.other');
    final assetGraphJsonId = AssetId('a', assetGraphJsonPath);

    late BuildPackages buildPackages;
    late ReaderWriter readerWriter;
    late BuildOptions buildOptions;
    late BuilderFactories builderFactories;
    late TestingOverrides testingOverrides;

    Future<BuildSpec> loadSpec([TestingOverrides? overrides]) async {
      return BuildSpec.load(
        builderFactories: builderFactories,
        buildOptions: buildOptions,
        testingOverrides: overrides ?? testingOverrides,
      );
    }

    Future<PreviousBuild> loadPreviousBuild([
      TestingOverrides? overrides,
    ]) async {
      return PreviousBuild.load(await loadSpec(overrides));
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
    });

    test('loads with no previous build state', () async {
      final previousBuild = await loadPreviousBuild();
      expect(previousBuild.buildState, null);
    });

    Future<void> writeBuildStateAndPlan(
      BuildState buildState,
      BuildSpecDigest buildPlanDigest,
    ) async {
      await readerWriter.writeAsBytes(
        assetGraphJsonId,
        AssetGraphJson.serialize(
          buildPlanDigest: buildPlanDigest,
          buildState: buildState,
          phasedAssetDeps: PhasedAssetDeps(),
        ),
      );
    }

    test('loads previous build state', () async {
      final spec = await loadSpec();
      final previousBuild = await PreviousBuild.load(spec);
      final buildState = previousBuild.buildState ?? BuildState();
      await writeBuildStateAndPlan(buildState, spec.buildPlanDigest);

      final reloadedBuild = await loadPreviousBuild();
      expect(reloadedBuild.buildState.toString(), buildState.toString());
    });

    test('discards previous build state if build phases changed', () async {
      final spec = await loadSpec();
      final previousBuild = await PreviousBuild.load(spec);
      final buildState = previousBuild.buildState ?? BuildState();
      await writeBuildStateAndPlan(buildState, spec.buildPlanDigest);

      final buildSpec2 = await BuildSpec.load(
        builderFactories: builderFactories,
        buildOptions: buildOptions,
        testingOverrides: testingOverrides.copyWith(
          builderDefinitions: [
            BuilderDefinition(''),
            BuilderDefinition('b2'),
          ].build(),
        ),
      );

      final reloadedBuild = await PreviousBuild.load(buildSpec2);
      expect(reloadedBuild.buildState, null);
    });

    test('tracks lost outputs if build phases changed', () async {
      final spec = await loadSpec(
        testingOverrides.copyWith(
          builderDefinitions: [
            BuilderDefinition('', hideOutput: false),
          ].build(),
        ),
      );
      final previousBuild = await PreviousBuild.load(spec);
      final buildState = previousBuild.buildState ?? BuildState();

      await readerWriter.writeAsString(outputId, '// output');
      final buildStepPlan = BuildStepPlan.compute(
        buildPhases: spec.buildPhases,
        placeholderIds: buildPackages.placeholderIds,
        sources: {assetId, assetId2},
      );
      final step = buildStepPlan.stepForDeclaredOutput(outputId);
      buildState.updateBuildStepResult(
        step,
        BuildStepResult((b) {
          b.isHidden = false;
          b.outputs[outputId] = AssetContent.digest(Digest(<int>[]));
        }),
      );
      await writeBuildStateAndPlan(buildState, spec.buildPlanDigest);

      final buildSpec2 = await BuildSpec.load(
        builderFactories: builderFactories,
        buildOptions: buildOptions,
        testingOverrides: testingOverrides.copyWith(
          builderDefinitions: [
            BuilderDefinition(''),
            BuilderDefinition('b2'),
          ].build(),
        ),
      );

      final reloadedBuild = await PreviousBuild.load(buildSpec2);
      expect(reloadedBuild.buildState, null);
      expect(
        reloadedBuild.incompatibleBuildOutputsToDelete,
        contains(outputId),
      );
    });

    test('discards previous build state if SDK version changed', () async {
      final spec = await loadSpec();
      final previousBuild = await PreviousBuild.load(spec);
      final buildState = previousBuild.buildState ?? BuildState();
      await writeBuildStateAndPlan(buildState, spec.buildPlanDigest);

      final spec2 = await BuildSpec.load(
        builderFactories: builderFactories,
        buildOptions: buildOptions,
        testingOverrides: testingOverrides.copyWith(
          builderDefinitions: [
            BuilderDefinition(''),
            BuilderDefinition('b2'),
          ].build(),
        ),
      );

      final reloadedBuild = await PreviousBuild.load(spec2);
      expect(reloadedBuild.buildState, null);
    });

    test('discards previous build state if packages changed', () async {
      final spec = await loadSpec();
      final previousBuild = await PreviousBuild.load(spec);
      final buildState = previousBuild.buildState ?? BuildState();
      await writeBuildStateAndPlan(buildState, spec.buildPlanDigest);

      final buildPackages2 = BuildPackages.singlePackageBuild('b', [
        BuildPackage.forTesting(name: 'b', watch: true, isOutput: true),
      ]);
      final reloadedBuild = await loadPreviousBuild(
        testingOverrides.copyWith(buildPackages: buildPackages2),
      );

      expect(reloadedBuild.buildState, null);
    });

    test(
      'discards previous build state if enabled experiments changed',
      () async {
        final spec = await loadSpec();
        final previousBuild = await PreviousBuild.load(spec);
        final buildState = previousBuild.buildState ?? BuildState();
        await writeBuildStateAndPlan(buildState, spec.buildPlanDigest);

        final reloadedBuild = await withEnabledExperiments(
          () async => loadPreviousBuild(),
          ['an_experiment'],
        );

        expect(reloadedBuild.buildState, null);
      },
    );

    test('tracks cleanBuild when build_plan.json does not exist', () async {
      final previousBuild = await loadPreviousBuild();
      expect(previousBuild.buildState, isNull);
    });

    test(
      'tracks cleanBuild when build_plan.json compileDigest is fresh',
      () async {
        final spec = await loadSpec();
        final previousBuild = await PreviousBuild.load(spec);
        await writeBuildStateAndPlan(
          previousBuild.buildState ?? BuildState(),
          spec.buildPlanDigest,
        );
        final reloadedBuild = await loadPreviousBuild();
        expect(reloadedBuild.buildState, isNotNull);
      },
    );

    test(
      'tracks cleanBuild when build_plan.json compileDigest is stale',
      () async {
        final spec = await loadSpec();
        final previousBuild = await PreviousBuild.load(spec);
        final staleDigest = spec.buildPlanDigest.rebuild(
          (b) => b.compileDigest = 'stale_digest',
        );
        await writeBuildStateAndPlan(
          previousBuild.buildState ?? BuildState(),
          staleDigest,
        );

        final reloadedBuild = await loadPreviousBuild();
        expect(reloadedBuild.buildState, isNull);
      },
    );

    test('tracks triggersChanged when triggers change', () async {
      final spec = await loadSpec();
      final previousBuild = await PreviousBuild.load(spec);
      final staleDigest = spec.buildPlanDigest.rebuild(
        (b) => b.buildTriggersDigest = 'triggers_1',
      );
      await writeBuildStateAndPlan(
        previousBuild.buildState ?? BuildState(),
        staleDigest,
      );

      final buildConfig2 = runInBuildConfigZone(
        () => BuildConfig(
          packageName: 'a',
          buildTargets: {
            'a|a': BuildTarget(
              builders: {
                '': TargetBuilderConfig(
                  generateFor: const InputSet(include: ['lib/*.dart']),
                ),
              },
            ),
          },
        ),
        'a',
        const <String>[],
      );

      final spec2 = await BuildSpec.load(
        builderFactories: builderFactories,
        buildOptions: buildOptions,
        testingOverrides: testingOverrides.copyWith(
          buildConfig: {'a': buildConfig2}.build(),
        ),
      );

      final reloadedBuild = await PreviousBuild.load(spec2);
      expect(reloadedBuild.buildState, isNotNull);
      expect(reloadedBuild.triggersChanged, isTrue);
    });

    test('tracks phaseOptionsChanged when builder options change', () async {
      final spec = await loadSpec();
      final previousBuild = await PreviousBuild.load(spec);
      final staleDigest = spec.buildPlanDigest.rebuild(
        (b) => b.inBuildPhasesOptionsDigests[0] = 'dummy_digest_1',
      );
      await writeBuildStateAndPlan(
        previousBuild.buildState ?? BuildState(),
        staleDigest,
      );

      final buildConfig2 = runInBuildConfigZone(
        () => BuildConfig(
          packageName: 'a',
          buildTargets: {
            'a|a': BuildTarget(
              builders: {
                '': TargetBuilderConfig(
                  options: const {'some_option': 'changed'},
                ),
              },
            ),
          },
        ),
        'a',
        const <String>[],
      );

      final spec2 = await BuildSpec.load(
        builderFactories: builderFactories,
        buildOptions: buildOptions,
        testingOverrides: testingOverrides.copyWith(
          buildConfig: {'a': buildConfig2}.build(),
        ),
      );

      final reloadedBuild = await PreviousBuild.load(spec2);
      expect(reloadedBuild.buildState, isNotNull);
      expect(reloadedBuild.phaseOptionsChangedList[0], isTrue);
    });

    test('tracks buildPhasesDigest when build phases change', () async {
      final spec = await loadSpec();
      final previousBuild = await PreviousBuild.load(spec);
      final staleDigest = spec.buildPlanDigest.rebuild(
        (b) => b.buildPhasesDigest = 'stale_digest',
      );
      await writeBuildStateAndPlan(
        previousBuild.buildState ?? BuildState(),
        staleDigest,
      );

      final reloadedBuild = await loadPreviousBuild();
      expect(reloadedBuild.buildState, isNull);
    });

    test('tracks dartVersion when SDK version changes', () async {
      final spec = await loadSpec();
      final previousBuild = await PreviousBuild.load(spec);
      final staleDigest = spec.buildPlanDigest.rebuild(
        (b) => b.dartVersion = 'stale_version',
      );
      await writeBuildStateAndPlan(
        previousBuild.buildState ?? BuildState(),
        staleDigest,
      );

      final reloadedBuild = await loadPreviousBuild();
      expect(reloadedBuild.buildState, isNull);
    });

    test('tracks enabledExperiments when experiments change', () async {
      final spec = await loadSpec();
      final previousBuild = await PreviousBuild.load(spec);
      final staleDigest = spec.buildPlanDigest.rebuild(
        (b) => b.enabledExperiments.add('stale_experiment'),
      );
      await writeBuildStateAndPlan(
        previousBuild.buildState ?? BuildState(),
        staleDigest,
      );

      final reloadedBuild = await loadPreviousBuild();
      expect(reloadedBuild.buildState, isNull);
    });

    test(
      'tracks packageLanguageVersions when package language versions change',
      () async {
        final spec = await loadSpec();
        final previousBuild = await PreviousBuild.load(spec);
        final staleDigest = spec.buildPlanDigest.rebuild(
          (b) => b.packageLanguageVersions['a'] = '1.0',
        );
        await writeBuildStateAndPlan(
          previousBuild.buildState ?? BuildState(),
          staleDigest,
        );

        final reloadedBuild = await loadPreviousBuild();
        expect(reloadedBuild.buildState, isNull);
      },
    );

    test('tracks cleanBuild when asset_graph.json version is stale', () async {
      final spec = await loadSpec();
      final previousBuild = await PreviousBuild.load(spec);
      await writeBuildStateAndPlan(
        previousBuild.buildState ?? BuildState(),
        spec.buildPlanDigest,
      );

      final decodedMap =
          json.decode(await readerWriter.readAsString(assetGraphJsonId)) as Map;
      decodedMap['version'] = 999;
      await readerWriter.writeAsString(
        assetGraphJsonId,
        json.encode(decodedMap),
      );

      final reloadedBuild = await loadPreviousBuild();
      expect(reloadedBuild.buildState, isNull);
    });
  });
}
