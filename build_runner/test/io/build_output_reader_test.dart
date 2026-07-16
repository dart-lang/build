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
import 'package:build_runner/src/build/builder_filesystem.dart';
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
  group('FinalizedReader', () {
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
      buildState = BuildState();
      buildPhases = BuildPhases([]);
    });

    test('can not read deleted files', () async {
      final notDeletedId = AssetId.parse('a|web/a.txt');
      final deletedId = AssetId.parse('a|lib/b.txt');

      buildState.addPostProcessBuildStepResult(
        PostProcessBuildStepId(input: deletedId, actionNumber: 0),
        PostProcessBuildStepResult(hidden: true, deletedPrimaryInput: true),
      );

      buildState
        ..addSourceForTest(
          notDeletedId,
          digest: AssetContent.digest(computeDigest(notDeletedId, 'a')),
        )
        ..addSourceForTest(
          deletedId,
          digest: AssetContent.digest(computeDigest(deletedId, 'b')),
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
        builderFilesystem: BuilderFilesystem(
          buildPackages: buildPlan.buildSpec.buildPackages,
          buildConfigs: buildPlan.buildSpec.buildConfigs,
          buildState: buildState,
          buildStepPlan: buildPlan.buildStepPlan,
          readerWriter: buildPlan.readerWriter,
        ),
      );
      expect(await reader.canRead(notDeletedId), true);
      expect(await reader.canRead(deletedId), false);
    });

    test('can fully read generated shared parts (retaining imports)', () async {
      final inputId = AssetId('a', 'lib/a.dart');
      final expectedGeneratedPartId = AssetId('a', 'lib/_br_/a.dart');

      final buildStepId = BuildStepId(primaryInput: inputId, phaseNumber: 0);
      buildState.updateBuildStepResult(
        buildStepId,
        BuildStepResult((b) {
          b.result = true;
          b.isHidden = false;
          b.partImports = AssetContent.string(
            'import \'package:foo/foo.dart\';\n',
          );
          b.partContribution = AssetContent.string('// contribution');
          b.primaryLanguageVersion = '// @dart=3.0';
        }),
      );

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
        builderFilesystem: BuilderFilesystem(
          buildPackages: buildPlan.buildSpec.buildPackages,
          buildConfigs: buildPlan.buildSpec.buildConfigs,
          buildState: buildState,
          buildStepPlan: buildPlan.buildStepPlan,
          readerWriter: buildPlan.readerWriter,
        ),
      );

      expect(await reader.canRead(expectedGeneratedPartId), true);
      final content = await reader.readAsString(expectedGeneratedPartId);
      expect(content, contains('import \'package:foo/foo.dart\';'));
      expect(content, contains('// @dart=3.0'));
      expect(content, contains('// contribution'));
    });

    test('Failed steps interact well with build filters ', () async {
      final id = AssetId('a', 'web/a.txt');
      final primaryId = AssetId('a', 'web/a.dart');
      final buildStepId = BuildStepId(primaryInput: primaryId, phaseNumber: 0);

      var buildState = BuildState();
      final stepResult = BuildStepResult((b) {
        b.result = false;
        b.isHidden = false;
      });
      buildState.updateBuildStepResult(buildStepId, stepResult);
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
      reader = BuildOutputReader(
        builderFilesystem: BuilderFilesystem(
          buildPackages: buildPlan.buildSpec.buildPackages,
          buildConfigs: buildPlan.buildSpec.buildConfigs,
          buildState: buildState,
          buildStepPlan: buildPlan.buildStepPlan,
          readerWriter: buildPlan.readerWriter,
        ),
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
      buildState = BuildState();

      reader = BuildOutputReader(
        builderFilesystem: BuilderFilesystem(
          buildPackages: buildPlan.buildSpec.buildPackages,
          buildConfigs: buildPlan.buildSpec.buildConfigs,
          buildState: buildState,
          buildStepPlan: buildPlan.buildStepPlan,
          readerWriter: buildPlan.readerWriter,
        ),
      );

      expect(
        await reader.unreadableReason(id),
        UnreadableReason.notOutput,
        reason:
            'Should report as not output if it doesn\'t match requested '
            'build filters',
      );
    });
  });
}
