// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:build_runner/src/build/asset_content.dart';
import 'package:build_runner/src/build/build_state/build_state.dart';
import 'package:build_runner/src/build/build_state/build_step_id.dart';
import 'package:build_runner/src/build/build_state/build_step_result.dart';
import 'package:build_runner/src/build/builder_filesystem.dart';
import 'package:build_runner/src/build/resolver/analysis_driver_filesystem.dart';
import 'package:build_runner/src/build_plan/build_configs.dart';
import 'package:build_runner/src/build_plan/build_inputs.dart';
import 'package:build_runner/src/build_plan/build_package.dart';
import 'package:build_runner/src/build_plan/build_packages.dart';
import 'package:build_runner/src/build_plan/build_phases.dart';
import 'package:build_runner/src/build_plan/build_step_plan.dart';
import 'package:build_test/src/internal_test_reader_writer.dart';
import 'package:built_collection/built_collection.dart';
import 'package:test/test.dart';

void main() {
  late AnalysisDriverFilesystem filesystem;
  late BuildPackages buildPackages;
  late InternalTestReaderWriter readerWriter;
  late BuildConfigs buildConfigs;
  late BuilderFilesystem builderFilesystem;

  BuilderFilesystem createBuilderFilesystem({
    Map<AssetId, AssetContent> sources = const {},
    Map<AssetId, int> generatedPhases = const {},
  }) {
    final buildStepPlan = BuildStepPlan((b) {
      for (final entry in generatedPhases.entries) {
        final phase = entry.value;
        final stepId = BuildStepId(
          primaryInput: AssetId('a', 'lib/a.dart'),
          phaseNumber: phase,
        );
        b.buildStepsByDeclaredOutput[entry.key] = stepId;

        while (b.buildStepsByPhase.length <= phase) {
          b.buildStepsByPhase.add(BuiltList<BuildStepId>());
        }
        final phaseSteps = b.buildStepsByPhase[phase].toList();
        if (!phaseSteps.contains(stepId)) phaseSteps.add(stepId);
        b.buildStepsByPhase[phase] = BuiltList<BuildStepId>(phaseSteps);

        b.declaredOutputsByStep.add(stepId, entry.key);
      }
      b.buildPhases = BuildPhases([]);
    });
    return BuilderFilesystem(
      buildPackages: buildPackages,
      buildConfigs: buildConfigs,
      buildState: BuildState(sources),
      buildStepPlan: buildStepPlan,
      readerWriter: readerWriter,
      assetBuilder: (_) async {},
      globEvaluator: (_) async {},
    );
  }

  setUp(() async {
    filesystem = AnalysisDriverFilesystem();
    buildPackages = BuildPackages.singlePackageBuild('a', [
      BuildPackage.forTesting(name: 'a', isOutput: true),
    ]);
    readerWriter = InternalTestReaderWriter(
      outputRootPackage: buildPackages.outputRoot,
    );
    buildConfigs = await BuildConfigs.load(
      buildPackages: buildPackages,
      readerWriter: readerWriter,
    );

    builderFilesystem = createBuilderFilesystem();
  });

  group('AnalysisDriverFilesystem', () {
    test('startBuild clean populates from sources and changedPaths', () {
      final sourceId = AssetId('a', 'lib/a.dart');
      final sourceContent = AssetContent.string('class A {}');

      builderFilesystem = createBuilderFilesystem(
        sources: {sourceId: sourceContent},
      );

      filesystem.startBuild(
        builderFilesystem: builderFilesystem,
        buildInputs: BuildInputs((b) => b..cleanBuild = true),
      );

      expect(filesystem.exists('/a/lib/a.dart'), isTrue);
      expect(filesystem.read('/a/lib/a.dart'), 'class A {}');
      expect(filesystem.changedPaths, {'/a/lib/a.dart'});
    });

    test('startBuild incremental syncs deleted and updated sources', () {
      final sourceA = AssetId('a', 'lib/a.dart');
      final sourceB = AssetId('a', 'lib/b.dart');

      builderFilesystem = createBuilderFilesystem(
        sources: {
          sourceA: AssetContent.string('A1'),
          sourceB: AssetContent.string('B1'),
        },
      );
      filesystem.startBuild(
        builderFilesystem: builderFilesystem,
        buildInputs: BuildInputs((b) => b..cleanBuild = true),
      );

      filesystem.clearChangedPaths();

      // Incremental build: Delete A, Update B.
      builderFilesystem = createBuilderFilesystem(
        sources: {sourceB: AssetContent.string('B2')},
      );
      filesystem.startBuild(
        builderFilesystem: builderFilesystem,
        buildInputs: BuildInputs(
          (b) => b
            ..cleanBuild = false
            ..deletedSources.add(sourceA)
            ..updatedSources.add(sourceB),
        ),
      );

      expect(filesystem.exists('/a/lib/a.dart'), isFalse);
      expect(filesystem.exists('/a/lib/b.dart'), isTrue);
      expect(filesystem.read('/a/lib/b.dart'), 'B2');
      expect(
        filesystem.changedPaths,
        unorderedEquals(['/a/lib/a.dart', '/a/lib/b.dart']),
      );
    });

    test('mid-build output generation updates cache and changedPaths', () {
      final outputId = AssetId('a', 'lib/out.g.dart');

      builderFilesystem = createBuilderFilesystem(
        generatedPhases: {outputId: 1},
      );

      filesystem.startBuild(
        builderFilesystem: builderFilesystem,
        buildInputs: BuildInputs((b) => b..cleanBuild = true),
      );

      expect(filesystem.exists('/a/lib/out.g.dart'), isFalse);

      // Mid-build, the builder generates the output.
      builderFilesystem.buildState.updateBuildStepResult(
        builderFilesystem.buildStepPlan.stepForDeclaredOutputOrNull(outputId)!,
        BuildStepResult(
          (b) => b
            ..result = true
            ..isHidden = false
            ..outputs[outputId] = AssetContent.string('generated'),
        ),
      );
      builderFilesystem.updateContent(
        id: outputId,
        content: AssetContent.string('generated'),
      );

      // Advance phase to make it visible.
      filesystem.phase = 2;

      expect(filesystem.exists('/a/lib/out.g.dart'), isTrue);
      expect(filesystem.read('/a/lib/out.g.dart'), 'generated');
      expect(filesystem.changedPaths, {'/a/lib/out.g.dart'});
    });

    test('files generated at later phases are visible when phase advances', () {
      final output1 = AssetId('a', 'lib/out1.g.dart');
      final output2 = AssetId('a', 'lib/out2.g.dart');

      builderFilesystem = createBuilderFilesystem(
        generatedPhases: {output1: 1, output2: 2},
      );

      filesystem.startBuild(
        builderFilesystem: builderFilesystem,
        buildInputs: BuildInputs((b) => b..cleanBuild = true),
      );

      builderFilesystem.buildState.updateBuildStepResult(
        builderFilesystem.buildStepPlan.stepForDeclaredOutputOrNull(output1)!,
        BuildStepResult(
          (b) => b
            ..result = true
            ..isHidden = false
            ..outputs[output1] = AssetContent.string('g1'),
        ),
      );
      builderFilesystem.updateContent(
        id: output1,
        content: AssetContent.string('g1'),
      );

      builderFilesystem.buildState.updateBuildStepResult(
        builderFilesystem.buildStepPlan.stepForDeclaredOutputOrNull(output2)!,
        BuildStepResult(
          (b) => b
            ..result = true
            ..isHidden = false
            ..outputs[output2] = AssetContent.string('g2'),
        ),
      );
      builderFilesystem.updateContent(
        id: output2,
        content: AssetContent.string('g2'),
      );
      filesystem.clearChangedPaths();

      // Phase 1 (executing): nothing visible yet.
      filesystem.phase = 1;
      expect(filesystem.exists('/a/lib/out1.g.dart'), isFalse);
      expect(filesystem.exists('/a/lib/out2.g.dart'), isFalse);

      // Phase 2: out1 is visible, out2 is executing.
      filesystem.phase = 2;
      expect(filesystem.exists('/a/lib/out1.g.dart'), isTrue);
      expect(filesystem.exists('/a/lib/out2.g.dart'), isFalse);
      expect(filesystem.changedPaths, {'/a/lib/out1.g.dart'});
      filesystem.clearChangedPaths();

      // Phase 3: out2 is visible.
      filesystem.phase = 3;
      expect(filesystem.exists('/a/lib/out1.g.dart'), isTrue);
      expect(filesystem.exists('/a/lib/out2.g.dart'), isTrue);
      expect(filesystem.changedPaths, {'/a/lib/out2.g.dart'});
    });
  });
}
