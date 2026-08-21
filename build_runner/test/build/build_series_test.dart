// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:build_runner/src/build/asset_content.dart';
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
import 'package:crypto/crypto.dart';
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
          buildState: buildState.toSerializedBuildState(),
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
        '': [(_) => TestBuilder()],
      });
      testingOverrides = TestingOverrides(
        builderDefinitions: [BuilderDefinition('', hideOutput: false)].build(),
        readerWriter: readerWriter,
        buildPackages: buildPackages,
        checkBuilderFreshness: false,
      );
      buildPlan = await loadPlan();
    });

    group('filterChanges', () {
      test('rejects change to unread source', () async {
        final buildState = BuildState(
          buildStepPlan: buildPlan.buildStepPlan,
          sources: {assetId: null},
        );
        await writeBuildStateAndPlan(buildState, buildPlan);
        final loadedPlan = await loadPlan();
        final buildSeries = BuildSeries(loadedPlan);

        final change = AssetChange(assetId, ChangeType.MODIFY);
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
          AssetContent.digest(Digest([1, 2, 3])),
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
        final digest = md5.convert(outputContent.codeUnits);
        await readerWriter.writeAsString(outputId, outputContent);
        final stepId = buildPlan.buildStepPlan.stepForDeclaredOutput(outputId);
        buildState.updateBuildStepResult(
          stepId,
          BuildStepResult((b) {
            b.isHidden = false;
            b.outputs[outputId] = AssetContent.digest(digest);
          }),
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
        final digest = Digest([1, 2, 3]);
        await readerWriter.writeAsString(outputId, '// different content');
        final stepId = buildPlan.buildStepPlan.stepForDeclaredOutput(outputId);
        buildState.updateBuildStepResult(
          stepId,
          BuildStepResult((b) {
            b.isHidden = false;
            b.outputs[outputId] = AssetContent.digest(digest);
          }),
        );
        await writeBuildStateAndPlan(buildState, buildPlan);
        final loadedPlan = await loadPlan();
        final buildSeries = BuildSeries(loadedPlan);

        final change = AssetChange(outputId, ChangeType.MODIFY);
        final filtered = await buildSeries.filterChanges([change]);

        expect(filtered.accepted, [change]);
        expect(filtered.rejected, isEmpty);
      });

      test(
        'accepts conflicting visible file when hidden output is unchanged',
        () async {
          final hiddenPlan = await loadPlan(
            TestingOverrides(
              builderDefinitions: [
                BuilderDefinition('', hideOutput: true),
              ].build(),
              readerWriter: readerWriter,
              buildPackages: buildPackages,
              checkBuilderFreshness: false,
            ),
          );
          final buildState = BuildState(
            buildStepPlan: hiddenPlan.buildStepPlan,
            sources: {assetId: null},
          );
          final outputContent = '// output';
          final digest = md5.convert(outputContent.codeUnits);
          await readerWriter.writeAsString(
            outputId,
            outputContent,
            hidden: true,
          );
          final stepId = hiddenPlan.buildStepPlan.stepForDeclaredOutput(
            outputId,
          );
          buildState.updateBuildStepResult(
            stepId,
            BuildStepResult((b) {
              b.isHidden = true;
              b.outputs[outputId] = AssetContent.digest(digest);
            }),
          );
          await writeBuildStateAndPlan(buildState, hiddenPlan);
          final loadedPlan = await loadPlan(
            TestingOverrides(
              builderDefinitions: [
                BuilderDefinition('', hideOutput: true),
              ].build(),
              readerWriter: readerWriter,
              buildPackages: buildPackages,
              checkBuilderFreshness: false,
            ),
          );
          final buildSeries = BuildSeries(loadedPlan);

          // A conflicting visible file is added.
          await readerWriter.writeAsString(
            outputId,
            '// visible conflict',
            hidden: false,
          );

          final change = AssetChange(outputId, ChangeType.ADD);
          final filtered = await buildSeries.filterChanges([change]);

          expect(filtered.accepted, [change]);
          expect(filtered.rejected, isEmpty);
        },
      );

      test(
        'accepts conflicting cache file when visible output is unchanged',
        () async {
          final buildState = BuildState(
            buildStepPlan: buildPlan.buildStepPlan,
            sources: {assetId: null},
          );
          final outputContent = '// output';
          final digest = md5.convert(outputContent.codeUnits);
          await readerWriter.writeAsString(
            outputId,
            outputContent,
            hidden: false,
          );
          final stepId = buildPlan.buildStepPlan.stepForDeclaredOutput(
            outputId,
          );
          buildState.updateBuildStepResult(
            stepId,
            BuildStepResult((b) {
              b.isHidden = false;
              b.outputs[outputId] = AssetContent.digest(digest);
            }),
          );
          await writeBuildStateAndPlan(buildState, buildPlan);
          final loadedPlan = await loadPlan();
          final buildSeries = BuildSeries(loadedPlan);

          // A conflicting cache file is found by manual scanning.
          await readerWriter.writeAsString(
            outputId,
            '// cache conflict',
            hidden: true,
          );

          final change = AssetChange(outputId, ChangeType.ADD);
          final filtered = await buildSeries.filterChanges([change]);

          expect(filtered.accepted, [change]);
          expect(filtered.rejected, isEmpty);
        },
      );
    });
  });
}
