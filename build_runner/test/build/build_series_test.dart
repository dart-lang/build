// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:build_runner/src/build/asset_content.dart';
import 'package:build_runner/src/build/build_result.dart';
import 'package:build_runner/src/build/build_series.dart';
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
import 'package:build_runner/src/commands/watch/asset_change.dart';
import 'package:build_runner/src/constants.dart';
import 'package:build_runner/src/io/reader_writer.dart';
import 'package:built_collection/built_collection.dart';
import 'package:test/test.dart';
import 'package:watcher/watcher.dart';

import '../common/common.dart';

void main() {
  setUpTestLogging();

  group('BuildSeries', () {
    final assetId = AssetId('a', 'lib/a.dart');
    final outputId = AssetId('a', 'lib/a.dart.copy');
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

    setUp(() async {
      buildPackages = BuildPackages.singlePackageBuild('a', [
        BuildPackage.forTesting(name: 'a', watch: true, isOutput: true),
      ]);
      readerWriter = InternalTestReaderWriter(outputRootPackage: 'a');
      await readerWriter.writeAsString(assetId, '// a.dart');
      buildOptions = BuildOptions.forTests();
      builderFactories = BuilderFactories({
        '': [
          (_) => TestBuilder(
            buildExtensions: const {
              '.dart': ['.dart.copy'],
            },
          ),
        ],
      });
      testingOverrides = TestingOverrides(
        builderDefinitions: [
          BuilderDefinition('', outputsToArtifactTree: false),
        ].build(),
        readerWriter: readerWriter,
        buildPackages: buildPackages,
        checkBuilderFreshness: false,
      );
      buildPlan = await loadPlan();
    });

    group('filterChanges', () {
      test('rejects change to unread source', () async {
        final unreadSourceId = AssetId('a', 'lib/no_outputs.txt');
        await readerWriter.writeAsString(unreadSourceId, '// no outputs');
        final buildState = BuildState(
          buildStepPlan: buildPlan.buildStepPlan,
          sources: {assetId: null, unreadSourceId: null},
        );
        await writeBuildStateAndPlan(buildState, buildPlan);
        final loadedPlan = await loadPlan();
        final buildSeries = BuildSeries(loadedPlan);

        final change = AssetChange(unreadSourceId, ChangeType.MODIFY);
        final filtered = await buildSeries.filterChanges([change]);

        expect(filtered.accepted, isEmpty);
        expect(filtered.rejected, [change]);
      });

      test('accepts change to read source', () async {
        final buildState = BuildState(
          buildStepPlan: buildPlan.buildStepPlan,
          sources: {assetId: null},
        );
        buildState.updateSourceContent(
          assetId,
          AssetContent.string('// a.dart'),
        );
        await writeBuildStateAndPlan(buildState, buildPlan);
        final loadedPlan = await loadPlan();
        final buildSeries = BuildSeries(loadedPlan);

        final change = AssetChange(assetId, ChangeType.MODIFY);
        final filtered = await buildSeries.filterChanges([change]);

        expect(filtered.accepted, [change]);
        expect(filtered.rejected, isEmpty);
      });

      test(
        'accepts change to declared output that was not generated',
        () async {
          final buildState = BuildState(
            buildStepPlan: buildPlan.buildStepPlan,
            sources: {assetId: null},
          );
          await writeBuildStateAndPlan(buildState, buildPlan);
          final loadedPlan = await loadPlan();
          final buildSeries = BuildSeries(loadedPlan);

          final change = AssetChange(outputId, ChangeType.ADD);
          final filtered = await buildSeries.filterChanges([change]);

          expect(filtered.accepted, [change]);
          expect(filtered.rejected, isEmpty);
        },
      );

      test(
        'accepts modification to declared output that was not generated',
        () async {
          final buildState = BuildState(
            buildStepPlan: buildPlan.buildStepPlan,
            sources: {assetId: null},
          );
          await writeBuildStateAndPlan(buildState, buildPlan);
          final loadedPlan = await loadPlan();
          final buildSeries = BuildSeries(loadedPlan);

          final change = AssetChange(outputId, ChangeType.MODIFY);
          final filtered = await buildSeries.filterChanges([change]);

          expect(filtered.accepted, [change]);
          expect(filtered.rejected, isEmpty);
        },
      );

      test('ignores write to generated output matching digest', () async {
        final buildState = BuildState(
          buildStepPlan: buildPlan.buildStepPlan,
          sources: {assetId: null},
        );
        final outputContent = '// output';
        await readerWriter.writeAsString(outputId, outputContent);
        final stepId = buildPlan.buildStepPlan.stepForDeclaredOutput(outputId);
        buildState.addBuildStepResult(
          step: stepId,
          result: BuildStepResult((b) {
            b.result = true;
            b.inArtifactTree = false;
            b.outputs.add(outputId);
          }),
          contents: {outputId: AssetContent.string(outputContent)},
        );
        await writeBuildStateAndPlan(buildState, buildPlan);
        final loadedPlan = await loadPlan();
        final buildSeries = BuildSeries(loadedPlan);

        final change = AssetChange(outputId, ChangeType.MODIFY);
        final filtered = await buildSeries.filterChanges([change]);

        expect(filtered.accepted, isEmpty);
        expect(filtered.rejected, isEmpty);
      });

      test('accepts write to generated output differing in digest', () async {
        final buildState = BuildState(
          buildStepPlan: buildPlan.buildStepPlan,
          sources: {assetId: null},
        );
        await readerWriter.writeAsString(outputId, '// different content');
        final stepId = buildPlan.buildStepPlan.stepForDeclaredOutput(outputId);
        buildState.addBuildStepResult(
          step: stepId,
          result: BuildStepResult((b) {
            b.result = true;
            b.inArtifactTree = false;
            b.outputs.add(outputId);
          }),
          contents: {outputId: AssetContent.string('// previous content')},
        );
        await writeBuildStateAndPlan(buildState, buildPlan);
        final loadedPlan = await loadPlan();
        final buildSeries = BuildSeries(loadedPlan);

        final change = AssetChange(outputId, ChangeType.MODIFY);
        final filtered = await buildSeries.filterChanges([change]);

        expect(filtered.accepted, [change]);
        expect(filtered.rejected, isEmpty);
      });

      test('accepts conflicting package path file when artifact tree output is '
          'unchanged', () async {
        final artifactTreePlan = await loadPlan(
          TestingOverrides(
            builderDefinitions: [
              BuilderDefinition('', outputsToArtifactTree: true),
            ].build(),
            readerWriter: readerWriter,
            buildPackages: buildPackages,
            checkBuilderFreshness: false,
          ),
        );
        final buildState = BuildState(
          buildStepPlan: artifactTreePlan.buildStepPlan,
          sources: {assetId: null},
        );
        final outputContent = '// output';
        await readerWriter.writeAsString(
          outputId,
          outputContent,
          inArtifactTree: true,
        );
        final stepId = artifactTreePlan.buildStepPlan.stepForDeclaredOutput(
          outputId,
        );
        buildState.addBuildStepResult(
          step: stepId,
          result: BuildStepResult((b) {
            b.result = true;
            b.inArtifactTree = true;
            b.outputs.add(outputId);
          }),
          contents: {outputId: AssetContent.string(outputContent)},
        );
        await writeBuildStateAndPlan(buildState, artifactTreePlan);
        final loadedPlan = await loadPlan(
          TestingOverrides(
            builderDefinitions: [
              BuilderDefinition('', outputsToArtifactTree: true),
            ].build(),
            readerWriter: readerWriter,
            buildPackages: buildPackages,
            checkBuilderFreshness: false,
          ),
        );
        final buildSeries = BuildSeries(loadedPlan);

        // A conflicting package path file is added.
        await readerWriter.writeAsString(outputId, '// package path conflict');

        final change = AssetChange(outputId, ChangeType.ADD);
        final filtered = await buildSeries.filterChanges([change]);

        expect(filtered.accepted, [change]);
        expect(filtered.rejected, isEmpty);
      });

      test('accepts conflicting artifact tree file when package path output is '
          'unchanged', () async {
        final buildState = BuildState(
          buildStepPlan: buildPlan.buildStepPlan,
          sources: {assetId: null},
        );
        final outputContent = '// output';
        await readerWriter.writeAsString(outputId, outputContent);
        final stepId = buildPlan.buildStepPlan.stepForDeclaredOutput(outputId);
        buildState.addBuildStepResult(
          step: stepId,
          result: BuildStepResult((b) {
            b.result = true;
            b.inArtifactTree = false;
            b.outputs.add(outputId);
          }),
          contents: {outputId: AssetContent.string(outputContent)},
        );
        await writeBuildStateAndPlan(buildState, buildPlan);
        final loadedPlan = await loadPlan();
        final buildSeries = BuildSeries(loadedPlan);

        // A conflicting artifact tree file is found by manual scanning.
        await readerWriter.writeAsString(
          outputId,
          '// artifact conflict',
          inArtifactTree: true,
        );

        final change = AssetChange(outputId, ChangeType.ADD);
        final filtered = await buildSeries.filterChanges([change]);

        expect(filtered.accepted, [change]);
        expect(filtered.rejected, isEmpty);
      });

      test('runs build step for existing source when unexpected artifact tree '
          'file appears', () async {
        final series = BuildSeries(buildPlan);
        final firstResult = await series.run({}, recentlyBootstrapped: true);
        expect(firstResult.status, BuildStatus.success);
        expect(firstResult.outputs, contains(outputId));

        // An unexpected artifact tree file appears at the source ID, and the
        // source is updated.
        await readerWriter.writeAsString(
          assetId,
          '// unexpected artifact',
          inArtifactTree: true,
        );
        await readerWriter.writeAsString(assetId, '// updated source');

        final change = AssetChange(assetId, ChangeType.MODIFY);
        final filtered = await series.filterChanges([change]);
        expect(filtered.accepted, [change]);

        final secondResult = await series.run({
          assetId,
        }, recentlyBootstrapped: false);

        expect(secondResult.status, BuildStatus.success);
        expect(secondResult.outputs, contains(outputId));
      });
    });

    group('currentBuildResult', () {
      test('completes with early exit result when build configuration requires '
          'restart', () async {
        final planWithBuilderDefinitions = await loadPlan(
          TestingOverrides(
            builderDefinitions: [
              BuilderDefinition('extra:builder', outputsToArtifactTree: false),
            ].build(),
            readerWriter: readerWriter,
            buildPackages: buildPackages,
            checkBuilderFreshness: false,
          ),
        );
        final series = BuildSeries(planWithBuilderDefinitions);
        final configId = AssetId('a', 'build.yaml');
        final result = await series.run({
          configId,
        }, recentlyBootstrapped: false);

        expect(result.failureType, FailureType.buildScriptChanged);
        expect(await series.currentBuildResult, result);
      });
    });
  });
}
