// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:build/build.dart';
import 'package:build/experiments.dart';
import 'package:build_config/build_config.dart' hide BuilderDefinition;
import 'package:build_runner/src/build/asset_graph/asset_graph_json.dart';
import 'package:build_runner/src/build/asset_graph/graph.dart';
import 'package:build_runner/src/build/library_cycle_graph/phased_asset_deps.dart';
import 'package:build_runner/src/build_plan/build_options.dart';
import 'package:build_runner/src/build_plan/build_package.dart';
import 'package:build_runner/src/build_plan/build_packages.dart';
import 'package:build_runner/src/build_plan/build_plan.dart';
import 'package:build_runner/src/build_plan/builder_definition.dart';
import 'package:build_runner/src/build_plan/builder_factories.dart';
import 'package:build_runner/src/build_plan/testing_overrides.dart';
import 'package:build_runner/src/constants.dart';
import 'package:build_runner/src/io/reader_writer.dart';
import 'package:built_collection/built_collection.dart';
import 'package:crypto/crypto.dart';
import 'package:test/test.dart';

import '../common/common.dart';

void main() {
  group('BuildPlan', () {
    final assetId = AssetId('a', 'lib/a.dart');
    final outputId = AssetId('a', 'lib/a.dart.copy');
    final assetId2 = AssetId('a', 'lib/an.other');
    final assetGraphId = AssetId('a', assetGraphPath);

    late BuildPackages buildPackages;
    late ReaderWriter readerWriter;
    late BuildOptions buildOptions;
    late BuilderFactories builderFactories;
    late TestingOverrides testingOverrides;
    late BuildPlan buildPlan;

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
      buildPlan = await BuildPlan.load(
        builderFactories: builderFactories,
        buildOptions: buildOptions,
        testingOverrides: testingOverrides,
      );
    });

    test('loads with no asset graph', () async {
      expect(buildPlan.takePreviousAssetGraph(), null);
    });

    Future<void> writeGraphAndPlan(
      BuildState assetGraph,
      BuildPlan buildPlan,
    ) async {
      await readerWriter.writeAsBytes(
        assetGraphId,
        AssetGraphJson.serialize(
          buildPlanDigest: buildPlan.buildPlanDigest,
          assetGraph: assetGraph,
          phasedAssetDeps: PhasedAssetDeps(),
        ),
      );
    }

    test('loads previous asset graph', () async {
      final assetGraph = buildPlan.takeAssetGraph();
      await writeGraphAndPlan(assetGraph, buildPlan);
      buildPlan = await BuildPlan.load(
        builderFactories: builderFactories,
        buildOptions: buildOptions,
        testingOverrides: testingOverrides,
      );
      final loadedGraph = buildPlan.takePreviousAssetGraph();

      expect(loadedGraph.toString(), assetGraph.toString());
    });

    test('requires restart if a factory is missing', () async {
      final buildPlan = await BuildPlan.load(
        builderFactories: builderFactories,
        buildOptions: buildOptions,
        testingOverrides: testingOverrides.copyWith(
          builderDefinitions: [BuilderDefinition('missing')].build(),
        ),
      );

      expect(buildPlan.buildPhases.inBuildPhases.isEmpty, true);
      expect(buildPlan.restartIsNeeded, true);
    });

    test('discards previous asset graph if build phases changed', () async {
      final assetGraph = buildPlan.takeAssetGraph();
      await writeGraphAndPlan(assetGraph, buildPlan);

      buildPlan = await BuildPlan.load(
        builderFactories: builderFactories,
        buildOptions: buildOptions,
        testingOverrides: testingOverrides.copyWith(
          builderDefinitions:
              [
                BuilderDefinition(''),
                // Apply a second builder so build phases change.
                BuilderDefinition('b2'),
              ].build(),
        ),
      );

      expect(buildPlan.takePreviousAssetGraph(), null);

      // The old graph is in [BuildPlan#filesToDelete] because it's invalid.
      expect(await readerWriter.canRead(assetGraphId), true);
      await buildPlan.deleteFilesAndFolders();
      buildPlan.readerWriter.cache.flush();
      expect(await readerWriter.canRead(assetGraphId), false);
    });

    test('tracks lost outputs if build phases changed', () async {
      var buildPlan = await BuildPlan.load(
        builderFactories: builderFactories,
        buildOptions: buildOptions,
        testingOverrides: testingOverrides.copyWith(
          builderDefinitions:
              [
                BuilderDefinition(
                  '',
                  // Hidden output is easy to find and delete, it's under one
                  // generated root. Unhide the output so there can be lost
                  // outputs.
                  hideOutput: false,
                ),
              ].build(),
        ),
      );
      final assetGraph = buildPlan.takeAssetGraph();

      // Write an output and add it to the asset graph as if it was built.
      await readerWriter.writeAsString(outputId, '// output');
      final step = assetGraph.stepForDeclaredOutput(outputId);
      assetGraph.updateBuildStepResult(
        step,
        assetGraph
            .stepResult(step)
            .rebuild((b) => b..outputs[outputId] = Digest([])),
      );
      await writeGraphAndPlan(assetGraph, buildPlan);

      buildPlan = await BuildPlan.load(
        builderFactories: builderFactories,
        buildOptions: buildOptions,
        testingOverrides: testingOverrides.copyWith(
          builderDefinitions:
              [
                BuilderDefinition(''),
                // Apply a second builder so build phases change.
                BuilderDefinition('b2'),
              ].build(),
        ),
      );

      expect(buildPlan.takePreviousAssetGraph(), null);
      expect(buildPlan.filesToDelete, isNotEmpty);

      // `BuildPlan` can delete lost outputs.
      expect(await readerWriter.canRead(outputId), true);
      await buildPlan.deleteFilesAndFolders();
      buildPlan.readerWriter.cache.flush();
      expect(await readerWriter.canRead(outputId), false);
    });

    test('discards previous asset graph if SDK version changed', () async {
      final assetGraph = buildPlan.takeAssetGraph();
      await writeGraphAndPlan(assetGraph, buildPlan);

      buildPlan = await BuildPlan.load(
        builderFactories: builderFactories,
        buildOptions: buildOptions,
        testingOverrides: testingOverrides.copyWith(
          builderDefinitions:
              [BuilderDefinition(''), BuilderDefinition('b2')].build(),
        ),
      );

      expect(buildPlan.takePreviousAssetGraph(), null);
    });

    test('discards previous asset graph if packages changed', () async {
      final assetGraph = buildPlan.takeAssetGraph();
      await writeGraphAndPlan(assetGraph, buildPlan);

      final buildPackages2 = BuildPackages.singlePackageBuild('b', [
        BuildPackage.forTesting(name: 'b', watch: true, isOutput: true),
      ]);
      final testingOverrides2 = testingOverrides.copyWith(
        buildPackages: buildPackages2,
      );
      buildPlan = await BuildPlan.load(
        builderFactories: builderFactories,
        buildOptions: buildOptions,
        testingOverrides: testingOverrides2,
      );

      expect(buildPlan.takePreviousAssetGraph(), null);
    });

    test(
      'discards previous asset graph if enabled experiments changed',
      () async {
        final assetGraph = buildPlan.takeAssetGraph();
        await writeGraphAndPlan(assetGraph, buildPlan);

        buildPlan = await withEnabledExperiments(
          () => BuildPlan.load(
            builderFactories: builderFactories,
            buildOptions: buildOptions,
            testingOverrides: testingOverrides,
          ),
          ['an_experiment'],
        );

        expect(buildPlan.takePreviousAssetGraph(), null);
      },
    );

    test('reports updates', () async {
      final assetGraph = buildPlan.takeAssetGraph();

      // Write an output and add it to the asset graph as if it was built.
      await readerWriter.writeAsString(outputId, '// output');
      final stepId = assetGraph.stepForDeclaredOutput(outputId);
      assetGraph.updateBuildStepResult(
        stepId,
        assetGraph
            .stepResult(stepId)
            .rebuild((b) => b..outputs[outputId] = Digest([])),
      );
      // Give digests to inputs so they are monitored for modifications.
      assetGraph.updateSourceDigest(assetId2, Digest([]));

      await writeGraphAndPlan(assetGraph, buildPlan);

      // Remove source.
      await readerWriter.delete(assetId);
      // Change source.
      await readerWriter.writeAsString(assetId2, 'changed');
      // Add source.
      final assetId3 = AssetId('a', 'lib/new.dart');
      await readerWriter.writeAsString(assetId3, '');

      // Remove generated.
      await readerWriter.delete(outputId);

      buildPlan = await BuildPlan.load(
        builderFactories: builderFactories,
        buildOptions: buildOptions,
        testingOverrides: testingOverrides,
      );

      expect(buildPlan.updates!, {assetId, assetId2, assetId3, outputId});
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
        builderFactories: builderFactories,
        buildOptions: buildOptions,
        testingOverrides: testingOverrides.copyWith(
          buildConfig: {'a': buildConfig1}.build(),
        ),
      );
      final assetGraph1 = buildPlan1.takeAssetGraph();
      // Matches the only `*.dart` source.
      expect(assetGraph1.sources, <AssetId>{assetId});

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
        builderFactories: builderFactories,
        buildOptions: buildOptions,
        testingOverrides: testingOverrides.copyWith(
          buildConfig: {'a': buildConfig2}.build(),
        ),
      );
      final assetGraph2 = buildPlan2.takeAssetGraph();
      // Matches the only `*.other` source.
      expect(assetGraph2.sources, <AssetId>{assetId2});
    });

    test('tracks cleanBuild when build_plan.json does not exist', () async {
      final plan = await BuildPlan.load(
        builderFactories: builderFactories,
        buildOptions: buildOptions,
        testingOverrides: testingOverrides,
      );
      expect(plan.cleanBuild, isTrue);
    });

    test(
      'tracks cleanBuild when build_plan.json compileDigest is fresh',
      () async {
        await writeGraphAndPlan(buildPlan.takeAssetGraph(), buildPlan);
        buildPlan = await BuildPlan.load(
          builderFactories: builderFactories,
          buildOptions: buildOptions,
          testingOverrides: testingOverrides,
        );
        expect(buildPlan.cleanBuild, isFalse);
      },
    );

    test(
      'tracks cleanBuild when build_plan.json compileDigest is stale',
      () async {
        buildPlan = buildPlan.copyWith(
          buildPlanDigest: buildPlan.buildPlanDigest.rebuild(
            (b) => b.compileDigest = 'stale_digest',
          ),
        );
        await writeGraphAndPlan(buildPlan.takeAssetGraph(), buildPlan);

        buildPlan = await BuildPlan.load(
          builderFactories: builderFactories,
          buildOptions: buildOptions,
          testingOverrides: testingOverrides,
        );
        expect(buildPlan.cleanBuild, isTrue);
      },
    );

    test('tracks triggersChanged when triggers change', () async {
      buildPlan = buildPlan.copyWith(
        buildPlanDigest: buildPlan.buildPlanDigest.rebuild(
          (b) => b.buildTriggersDigest = 'triggers_1',
        ),
      );
      await writeGraphAndPlan(buildPlan.takeAssetGraph(), buildPlan);

      final buildConfig2 = runInBuildConfigZone(
        () {
          return BuildConfig(
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
          );
        },
        'a',
        [],
      );

      final buildPlan2 = await BuildPlan.load(
        builderFactories: builderFactories,
        buildOptions: buildOptions,
        testingOverrides: testingOverrides.copyWith(
          buildConfig: {'a': buildConfig2}.build(),
        ),
      );
      expect(buildPlan2.cleanBuild, isFalse);
      expect(buildPlan2.triggersChanged, isTrue);
    });

    test('tracks phaseOptionsChanged when builder options change', () async {
      buildPlan = buildPlan.copyWith(
        buildPlanDigest: buildPlan.buildPlanDigest.rebuild(
          (b) => b.inBuildPhasesOptionsDigests[0] = 'dummy_digest_1',
        ),
      );
      await writeGraphAndPlan(buildPlan.takeAssetGraph(), buildPlan);

      final buildConfig2 = runInBuildConfigZone(
        () {
          return BuildConfig(
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
          );
        },
        'a',
        [],
      );

      final buildPlan2 = await BuildPlan.load(
        builderFactories: builderFactories,
        buildOptions: buildOptions,
        testingOverrides: testingOverrides.copyWith(
          buildConfig: {'a': buildConfig2}.build(),
        ),
      );
      expect(buildPlan2.cleanBuild, isFalse);
      expect(buildPlan2.phaseOptionsChanged(0), isTrue);
    });

    test('tracks buildPhasesDigest when build phases change', () async {
      buildPlan = buildPlan.copyWith(
        buildPlanDigest: buildPlan.buildPlanDigest.rebuild(
          (b) => b.buildPhasesDigest = 'stale_digest',
        ),
      );
      await writeGraphAndPlan(buildPlan.takeAssetGraph(), buildPlan);

      buildPlan = await BuildPlan.load(
        builderFactories: builderFactories,
        buildOptions: buildOptions,
        testingOverrides: testingOverrides,
      );
      expect(buildPlan.cleanBuild, isTrue);
    });

    test('tracks dartVersion when SDK version changes', () async {
      buildPlan = buildPlan.copyWith(
        buildPlanDigest: buildPlan.buildPlanDigest.rebuild(
          (b) => b.dartVersion = 'stale_version',
        ),
      );
      await writeGraphAndPlan(buildPlan.takeAssetGraph(), buildPlan);

      buildPlan = await BuildPlan.load(
        builderFactories: builderFactories,
        buildOptions: buildOptions,
        testingOverrides: testingOverrides,
      );
      expect(buildPlan.cleanBuild, isTrue);
    });

    test('tracks enabledExperiments when experiments change', () async {
      buildPlan = buildPlan.copyWith(
        buildPlanDigest: buildPlan.buildPlanDigest.rebuild(
          (b) => b.enabledExperiments.add('stale_experiment'),
        ),
      );
      await writeGraphAndPlan(buildPlan.takeAssetGraph(), buildPlan);

      buildPlan = await BuildPlan.load(
        builderFactories: builderFactories,
        buildOptions: buildOptions,
        testingOverrides: testingOverrides,
      );
      expect(buildPlan.cleanBuild, isTrue);
    });

    test(
      'tracks packageLanguageVersions when package language versions change',
      () async {
        buildPlan = buildPlan.copyWith(
          buildPlanDigest: buildPlan.buildPlanDigest.rebuild(
            (b) => b.packageLanguageVersions['a'] = '1.0',
          ),
        );
        await writeGraphAndPlan(buildPlan.takeAssetGraph(), buildPlan);

        buildPlan = await BuildPlan.load(
          builderFactories: builderFactories,
          buildOptions: buildOptions,
          testingOverrides: testingOverrides,
        );
        expect(buildPlan.cleanBuild, isTrue);
      },
    );

    test('tracks cleanBuild when asset_graph.json version is stale', () async {
      final assetGraphId = AssetId(buildPackages.outputRoot, assetGraphPath);
      await writeGraphAndPlan(buildPlan.takeAssetGraph(), buildPlan);

      final decodedMap =
          json.decode(await readerWriter.readAsString(assetGraphId)) as Map;
      decodedMap['version'] = 999;
      await readerWriter.writeAsString(assetGraphId, json.encode(decodedMap));

      buildPlan = await BuildPlan.load(
        builderFactories: builderFactories,
        buildOptions: buildOptions,
        testingOverrides: testingOverrides,
      );
      expect(buildPlan.cleanBuild, isTrue);
    });
  });
}
