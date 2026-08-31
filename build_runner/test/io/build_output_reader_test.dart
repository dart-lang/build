// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
library;

import 'package:build/build.dart';
import 'package:build_runner/src/build/asset_content.dart';
import 'package:build_runner/src/build/build_state/build_state.dart';
import 'package:build_runner/src/build/build_state/build_step_id.dart';
import 'package:build_runner/src/build/build_state/build_step_result.dart';
import 'package:build_runner/src/build/build_state/post_process_build_step_id.dart';
import 'package:build_runner/src/build/build_state/post_process_build_step_result.dart';
import 'package:build_runner/src/build_plan/build_directory.dart';
import 'package:build_runner/src/build_plan/build_filter.dart';
import 'package:build_runner/src/build_plan/build_options.dart';
import 'package:build_runner/src/build_plan/build_package.dart';
import 'package:build_runner/src/build_plan/build_packages.dart';
import 'package:build_runner/src/build_plan/build_phases.dart';
import 'package:build_runner/src/build_plan/build_plan.dart';
import 'package:build_runner/src/build_plan/build_spec.dart';
import 'package:build_runner/src/build_plan/builder_factories.dart';
import 'package:build_runner/src/build_plan/phase.dart';
import 'package:build_runner/src/build_plan/testing_overrides.dart';
import 'package:build_runner/src/io/build_output_reader.dart';
import 'package:built_collection/built_collection.dart';
import 'package:glob/glob.dart';
import 'package:test/test.dart';

import '../common/common.dart';

void main() {
  group('BuildOutputReader', () {
    BuildOutputReader reader;
    late InternalTestReaderWriter readerWriter;
    late BuildState buildState;
    late BuildPackages buildPackages;
    late BuildPhases buildPhases;

    setUp(() async {
      readerWriter = InternalTestReaderWriter(outputRootPackage: 'a');
      buildPackages = BuildPackages.singlePackageBuild('a', [
        BuildPackage.forTesting(name: 'a', isOutput: true),
      ]);
      buildState = BuildState.empty();
      buildPhases = BuildPhases([]);
    });

    test(
      'rereads source not part of the build when disk content changes',
      () async {
        final id = AssetId('a', 'web/a.txt');
        buildState.addSourceForTest(id);
        readerWriter.testing.writeString(id, 'initial');

        final buildPlan = await BuildPlan.load(
          await BuildSpec.load(
            builderFactories: BuilderFactories({}),
            buildOptions: BuildOptions.forTests(),
            testingOverrides: TestingOverrides(
              buildPhases: buildPhases,
              readerWriter: readerWriter,
              buildPackages: buildPackages,
            ),
          ),
        );
        reader = BuildOutputReader(
          buildPackages: buildPlan.buildSpec.buildPackages,
          readerWriter: buildPlan.readerWriter,
          buildState: buildState.toFinishedBuildState(),
        );

        expect(await reader.readAsString(id), 'initial');

        readerWriter.testing.writeString(id, 'modified');
        expect(await reader.readAsString(id), 'modified');
      },
    );

    test(
      'does not reread source part of the build when disk content changes',
      () async {
        final id = AssetId('a', 'web/a.txt');
        buildState.addSourceForTest(
          id,
          content: AssetContent.string('initial'),
        );
        readerWriter.testing.writeString(id, 'initial');

        final buildPlan = await BuildPlan.load(
          await BuildSpec.load(
            builderFactories: BuilderFactories({}),
            buildOptions: BuildOptions.forTests(),
            testingOverrides: TestingOverrides(
              buildPhases: buildPhases,
              readerWriter: readerWriter,
              buildPackages: buildPackages,
            ),
          ),
        );
        reader = BuildOutputReader(
          buildPackages: buildPlan.buildSpec.buildPackages,
          readerWriter: buildPlan.readerWriter,
          buildState: buildState.toFinishedBuildState(),
        );

        expect(await reader.readAsString(id), 'initial');

        readerWriter.testing.writeString(id, 'modified');
        expect(await reader.readAsString(id), 'initial');
      },
    );

    test('can not read deleted files', () async {
      final notDeletedId = AssetId.parse('a|web/a.txt');
      final deletedId = AssetId.parse('a|lib/b.txt');

      buildState.addPostProcessBuildStepResult(
        step: PostProcessBuildStepId(input: deletedId, actionNumber: 0),
        result: PostProcessBuildStepResult(
          inArtifactTree: true,
          deletedPrimaryInput: true,
        ),
      );

      buildState
        ..addSourceForTest(
          notDeletedId,
          content: AssetContent.string(
            'a',
            digest: computeDigest(notDeletedId, 'a'),
          ),
        )
        ..addSourceForTest(
          deletedId,
          content: AssetContent.string(
            'b',
            digest: computeDigest(deletedId, 'b'),
          ),
        );

      readerWriter.testing.writeString(notDeletedId, '');
      readerWriter.testing.writeString(deletedId, '');

      final buildPlan = await BuildPlan.load(
        await BuildSpec.load(
          builderFactories: BuilderFactories({}),
          buildOptions: BuildOptions.forTests(),
          testingOverrides: TestingOverrides(
            buildPhases: buildPhases,
            readerWriter: readerWriter,
            buildPackages: buildPackages,
          ),
        ),
      );
      reader = BuildOutputReader(
        buildPackages: buildPlan.buildSpec.buildPackages,
        readerWriter: buildPlan.readerWriter,
        buildState: buildState.toFinishedBuildState(),
      );
      expect(await reader.canRead(notDeletedId), true);
      expect(await reader.canRead(deletedId), false);
    });

    test('Failed steps interact well with build filters ', () async {
      final id = AssetId('a', 'web/a.txt');
      final primaryId = AssetId('a', 'web/a.dart');
      final buildStepId = BuildStepId(primaryInput: primaryId, phaseNumber: 0);

      readerWriter.testing.writeString(primaryId, '');
      readerWriter.testing.writeString(id, '');

      buildPhases = BuildPhases([
        InBuildPhase(
          builder: TestBuilder(
            buildExtensions: replaceExtension('.dart', '.txt'),
          ),
          key: 'TestBuilder',
          package: 'a',
          isOptional: false,
        ),
      ]);

      var buildPlan = await BuildPlan.load(
        await BuildSpec.load(
          builderFactories: BuilderFactories({}),
          buildOptions: BuildOptions.forTests(
            buildDirs: {BuildDirectory('web')}.build(),
          ),
          testingOverrides: TestingOverrides(
            buildPhases: buildPhases,
            readerWriter: readerWriter,
            buildPackages: buildPackages,
          ),
        ),
      );
      var buildState = BuildState(
        buildStepPlan: buildPlan.buildStepPlan,
        sources: const {},
      );
      final stepResult = BuildStepResult((b) {
        b.result = false;
        b.inArtifactTree = false;
      });
      buildState.addBuildStepResult(step: buildStepId, result: stepResult);
      reader = BuildOutputReader(
        buildPackages: buildPlan.buildSpec.buildPackages,
        readerWriter: buildPlan.readerWriter,
        buildState: buildState.toFinishedBuildState(),
      );
      expect(
        await reader.unreadableReason(id),
        UnreadableReason.failed,
        reason: 'Should report a failure if no build filters apply',
      );

      buildPlan = await BuildPlan.load(
        await BuildSpec.load(
          builderFactories: BuilderFactories({}),
          buildOptions: BuildOptions.forTests(
            buildDirs: {BuildDirectory('web')}.build(),
            buildFilters: {BuildFilter(Glob('b'), Glob('foo'))}.build(),
          ),
          testingOverrides: TestingOverrides(
            buildPhases: buildPhases,
            readerWriter: readerWriter,
            buildPackages: buildPackages,
          ),
        ),
      );

      // If a step is skipped due to build filters it is not evaluated and its
      // result is not added to the buildState.
      buildState = BuildState(
        buildStepPlan: buildPlan.buildStepPlan,
        sources: const {},
      );

      reader = BuildOutputReader(
        buildPackages: buildPlan.buildSpec.buildPackages,
        readerWriter: buildPlan.readerWriter,
        buildState: buildState.toFinishedBuildState(),
      );

      expect(
        await reader.unreadableReason(id),
        UnreadableReason.notOutput,
        reason:
            'Should report as not output if it doesn\'t match requested '
            'build filters',
      );
    });

    test('allAssets filters actualPostOutputs by rootDir', () async {
      final postOutput = AssetId('a', 'test/post_output.txt');

      final postProcessId = PostProcessBuildStepId(
        input: AssetId('a', 'test/foo.txt'),
        actionNumber: 0,
      );

      buildState.addPostProcessBuildStepResult(
        step: postProcessId,
        result: PostProcessBuildStepResult(
          inArtifactTree: false,
          deletedPrimaryInput: false,
          outputs: [postOutput],
        ),
        contents: {
          postOutput: AssetContent.string(
            'a',
            digest: computeDigest(postOutput, 'a'),
          ),
        },
      );

      final buildPlan = await BuildPlan.load(
        await BuildSpec.load(
          builderFactories: BuilderFactories({}),
          buildOptions: BuildOptions.forTests(
            buildDirs: {BuildDirectory('web')}.build(),
          ),
          testingOverrides: TestingOverrides(
            buildPhases: buildPhases,
            readerWriter: readerWriter,
            buildPackages: buildPackages,
          ),
        ),
      );

      reader = BuildOutputReader(
        buildPackages: buildPlan.buildSpec.buildPackages,
        readerWriter: buildPlan.readerWriter,
        buildState: buildState.toFinishedBuildState(),
      );

      final webAssets = reader.allAssets(rootDir: 'web');
      expect(webAssets, isNot(contains(postOutput)));

      final testAssets = reader.allAssets(rootDir: 'test');
      expect(testAssets, contains(postOutput));
    });

    test('marks files as consumed outside build on read or digest, but not on '
        'canRead', () async {
      final id = AssetId('a', 'web/a.txt');
      buildState.addSourceForTest(id);
      readerWriter.testing.writeString(id, 'initial');

      final buildPlan = await BuildPlan.load(
        await BuildSpec.load(
          builderFactories: BuilderFactories({}),
          buildOptions: BuildOptions.forTests(),
          testingOverrides: TestingOverrides(
            buildPhases: buildPhases,
            readerWriter: readerWriter,
            buildPackages: buildPackages,
          ),
        ),
      );
      reader = BuildOutputReader(
        buildPackages: buildPlan.buildSpec.buildPackages,
        readerWriter: buildPlan.readerWriter,
        buildState: buildState.toFinishedBuildState(),
      );

      expect(reader.wasSourceConsumedOutsideBuild(id), isFalse);
      expect(await reader.canRead(id), isTrue);
      expect(await reader.unreadableReason(id), isNull);
      expect(reader.wasSourceConsumedOutsideBuild(id), isFalse);

      expect(await reader.digest(id), isNotNull);
      expect(reader.wasSourceConsumedOutsideBuild(id), isTrue);
    });

    test(
      'marks files as consumed outside build only when contentOfSource is null',
      () async {
        final unusedSourceId = AssetId('a', 'web/unused.txt');
        final usedSourceId = AssetId('a', 'web/used.txt');
        final generatedId = AssetId('a', 'web/gen.txt');
        final postProcessId = PostProcessBuildStepId(
          input: usedSourceId,
          actionNumber: 0,
        );

        buildState.addSourceForTest(unusedSourceId);
        buildState.addSourceForTest(
          usedSourceId,
          content: AssetContent.string('used content'),
        );
        buildState.addPostProcessBuildStepResult(
          step: postProcessId,
          result: PostProcessBuildStepResult(
            inArtifactTree: false,
            deletedPrimaryInput: false,
            outputs: [generatedId],
          ),
          contents: {generatedId: AssetContent.string('generated content')},
        );

        readerWriter.testing.writeString(unusedSourceId, 'unused content');
        readerWriter.testing.writeString(usedSourceId, 'used content');
        readerWriter.testing.writeString(generatedId, 'generated content');

        final buildPlan = await BuildPlan.load(
          await BuildSpec.load(
            builderFactories: BuilderFactories({}),
            buildOptions: BuildOptions.forTests(),
            testingOverrides: TestingOverrides(
              buildPhases: buildPhases,
              readerWriter: readerWriter,
              buildPackages: buildPackages,
            ),
          ),
        );
        reader = BuildOutputReader(
          buildPackages: buildPlan.buildSpec.buildPackages,
          readerWriter: buildPlan.readerWriter,
          buildState: buildState.toFinishedBuildState(),
        );

        // Reading an unused source marks it consumed outside the build.
        await reader.readAsString(unusedSourceId);
        expect(reader.wasSourceConsumedOutsideBuild(unusedSourceId), isTrue);

        // Reading a used source does not mark it consumed outside the build.
        await reader.readAsString(usedSourceId);
        expect(reader.wasSourceConsumedOutsideBuild(usedSourceId), isFalse);

        // Reading a generated output does not mark it consumed outside the
        // build.
        await reader.readAsString(generatedId);
        expect(reader.wasSourceConsumedOutsideBuild(generatedId), isFalse);
      },
    );
  });
}
