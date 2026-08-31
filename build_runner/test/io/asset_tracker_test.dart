// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:build/build.dart';
import 'package:build_runner/src/build/asset_content.dart';
import 'package:build_runner/src/build/build_state/build_state.dart';
import 'package:build_runner/src/build/build_state/build_step_id.dart';
import 'package:build_runner/src/build/build_state/build_step_result.dart';
import 'package:build_runner/src/build/build_state/finished_build_state.dart';
import 'package:build_runner/src/build/build_state/post_process_build_step_id.dart';
import 'package:build_runner/src/build/build_state/post_process_build_step_result.dart';
import 'package:build_runner/src/build_plan/asset_file.dart';
import 'package:build_runner/src/build_plan/build_configs.dart';
import 'package:build_runner/src/build_plan/build_package.dart';
import 'package:build_runner/src/build_plan/build_packages.dart';
import 'package:build_runner/src/build_plan/build_phases.dart';
import 'package:build_runner/src/build_plan/build_step_plan.dart';
import 'package:build_runner/src/build_plan/phase.dart';
import 'package:build_runner/src/build_plan/previous_build.dart';
import 'package:build_runner/src/build_plan/testing_overrides.dart';
import 'package:build_runner/src/io/asset_tracker.dart';
import 'package:build_runner/src/io/reader_writer.dart';
import 'package:built_collection/built_collection.dart';
import 'package:package_config/package_config.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;
import 'package:watcher/watcher.dart';

import '../common/common.dart';

void main() {
  setUpTestLogging();

  group('AssetTracker.collectChanges()', () {
    late AssetTracker assetTracker;
    late FinishedBuildState finishedBuildState;
    late BuildStepPlan buildStepPlan;

    setUp(() async {
      buildStepPlan = BuildStepPlan(
        (BuildStepPlanBuilder b) =>
            b..buildPhases = BuildPhases(const <InBuildPhase>[]),
      );
      await d.dir('a', [
        d.dir('web', [d.file('a.txt', 'hello')]),
        d.dir('.dart_tool', [
          d.file(
            'package_config.json',
            jsonEncode({'configVersion': 2, 'packages': <Object>[]}),
          ),
        ]),
      ]).create();
      final buildPackages = BuildPackages.singlePackageBuild('a', [
        BuildPackage(
          name: 'a',
          path: p.join(d.sandbox, 'a'),
          languageVersion: LanguageVersion(2, 6),
          watch: true,
          isOutput: true,
        ),
      ]);
      final reader = ReaderWriter(buildPackages);
      final aId = AssetId('a', 'web/a.txt');
      final buildState = BuildState(
        buildStepPlan: buildStepPlan,
        sources: {aId: null},
      );
      // Record the initial content so the finished state has a digest for
      // change detection.
      final bytes = await reader.readAsBytes(aId);
      final digest = await reader.digest(aId);
      buildState.updateSourceContent(
        aId,
        AssetContent.bytes(bytes, digest: digest),
      );
      finishedBuildState = buildState.toFinishedBuildState();

      final buildConfigs = await BuildConfigs.load(
        buildPackages: buildPackages,
        testingOverrides: TestingOverrides(
          defaultRootPackageSources: ['web/**'].build(),
        ),
      );
      assetTracker = AssetTracker(reader, buildPackages, buildConfigs);
      final updates = await assetTracker.collectChanges(
        previousBuild: PreviousBuild.fromFinishedBuildState(finishedBuildState),
      );
      // Advance buildState for the next tests so these initial sources are
      // known.
      final newSources = finishedBuildState.sources.toSet();
      for (final entry in updates.entries) {
        if (entry.value != ChangeType.REMOVE) {
          newSources.add(entry.key.id);
        } else {
          newSources.remove(entry.key.id);
        }
      }
      final nextState = BuildState(
        buildStepPlan: buildStepPlan,
        sources: {for (final s in newSources) s: null},
      );
      for (final id in newSources) {
        if (finishedBuildState.isSource(id)) {
          final digest = finishedBuildState.contentOf(id);
          if (digest != null) nextState.updateSourceContent(id, digest);
        }
      }
      finishedBuildState = nextState.toFinishedBuildState();

      // We should see no changes initially other than new sdk sources
      expect(
        updates..removeWhere(
          (file, type) => file.id.package == r'$sdk' && type == ChangeType.ADD,
        ),
        isEmpty,
      );
    });

    test('Collects file edits', () async {
      File(p.join(d.sandbox, 'a', 'web', 'a.txt')).writeAsStringSync('goodbye');

      expect(
        await assetTracker.collectChanges(
          previousBuild: PreviousBuild.fromFinishedBuildState(
            finishedBuildState,
          ),
        ),
        {AssetFile.source(AssetId('a', 'web/a.txt')): ChangeType.MODIFY},
      );
    });

    test('Collects new files', () async {
      File(p.join(d.sandbox, 'a', 'web', 'b.txt')).writeAsStringSync('yo!');

      expect(
        await assetTracker.collectChanges(
          previousBuild: PreviousBuild.fromFinishedBuildState(
            finishedBuildState,
          ),
        ),
        {AssetFile.source(AssetId('a', 'web/b.txt')): ChangeType.ADD},
      );
    });

    test('Collects new cache files', () async {
      final generatedDir = Directory(
        p.join(d.sandbox, 'a', '.dart_tool', 'build', 'generated', 'a', 'web'),
      );
      generatedDir.createSync(recursive: true);
      File(p.join(generatedDir.path, 'cache.txt')).writeAsStringSync('cached');

      expect(
        await assetTracker.collectChanges(
          previousBuild: PreviousBuild.fromFinishedBuildState(
            finishedBuildState,
          ),
        ),
        {AssetFile.cache(AssetId('a', 'web/cache.txt')): ChangeType.ADD},
      );
    });

    test(
      'Collects new cache file for declared-but-not-actual hidden output',
      () async {
        final outputId = AssetId('a', 'web/a.txt.hidden');

        final generatedDir = Directory(
          p.join(
            d.sandbox,
            'a',
            '.dart_tool',
            'build',
            'generated',
            'a',
            'web',
          ),
        );
        generatedDir.createSync(recursive: true);
        File(
          p.join(generatedDir.path, 'a.txt.hidden'),
        ).writeAsStringSync('hidden');

        final changes = await assetTracker.collectChanges(
          previousBuild: PreviousBuild.fromFinishedBuildState(
            finishedBuildState,
          ),
        );
        changes.removeWhere((file, type) => file.id.package == r'$sdk');
        expect(changes, {AssetFile.cache(outputId): ChangeType.ADD});
      },
    );

    test('Collects deleted files', () async {
      File(p.join(d.sandbox, 'a', 'web', 'a.txt')).deleteSync();

      expect(
        await assetTracker.collectChanges(
          previousBuild: PreviousBuild.fromFinishedBuildState(
            finishedBuildState,
          ),
        ),
        {AssetFile.source(AssetId('a', 'web/a.txt')): ChangeType.REMOVE},
      );
    });

    test(
      'Does not collect absent declared outputs that were not generated',
      () async {
        final emptyBuildState = FinishedBuildState.empty();

        File(p.join(d.sandbox, 'a', 'web', 'a.txt')).deleteSync();

        final changes = await assetTracker.collectChanges(
          previousBuild: PreviousBuild.fromFinishedBuildState(emptyBuildState),
        );
        changes.removeWhere((file, type) => file.id.package == r'$sdk');
        expect(changes, isEmpty);
      },
    );

    test('Collects deleted actual outputs', () async {
      File(p.join(d.sandbox, 'a', 'web', 'a.txt')).deleteSync();

      final outputId = AssetId('a', 'web/a.txt');
      final buildStepId = BuildStepId(
        primaryInput: AssetId('a', 'web/a.dart'),
        phaseNumber: 0,
      );

      final planWithOutput = BuildStepPlan(
        (BuildStepPlanBuilder b) => b
          ..buildPhases = BuildPhases([
            InBuildPhase(
              builder: TestBuilder(),
              key: 'a:builder',
              package: 'a',
              hideOutput: false,
            ),
          ])
          ..buildStepsByDeclaredOutput.addAll({outputId: buildStepId}),
      );

      final buildState = BuildState(buildStepPlan: planWithOutput, sources: {});
      buildState.addBuildStepResult(
        step: buildStepId,
        result: BuildStepResult((b) {
          b.result = true;
          b.isHidden = false;
          b.outputs.add(outputId);
        }),
        contents: {
          outputId: AssetContent.bytes([1, 2, 3]),
        },
      );

      final changes = await assetTracker.collectChanges(
        previousBuild: PreviousBuild.fromFinishedBuildState(
          buildState.toFinishedBuildState(),
        ),
      );
      changes.removeWhere((file, type) => file.id.package == r'$sdk');
      expect(changes, {AssetFile.source(outputId): ChangeType.REMOVE});
    });

    test('Collects deleted actual post process outputs', () async {
      File(p.join(d.sandbox, 'a', 'web', 'a.txt')).deleteSync();

      final outputId = AssetId('a', 'web/a.txt');
      final postStepId = PostProcessBuildStepId(
        input: AssetId('a', 'web/a.dart'),
        actionNumber: 0,
      );

      final buildState = BuildState(buildStepPlan: buildStepPlan, sources: {});
      buildState.addPostProcessBuildStepResult(
        step: postStepId,
        result: PostProcessBuildStepResult(hidden: false, outputs: [outputId]),
        contents: {
          outputId: AssetContent.bytes([1, 2, 3]),
        },
      );

      final changes = await assetTracker.collectChanges(
        previousBuild: PreviousBuild.fromFinishedBuildState(
          buildState.toFinishedBuildState(),
        ),
      );
      changes.removeWhere((file, type) => file.id.package == r'$sdk');
      expect(changes, {AssetFile.source(outputId): ChangeType.REMOVE});
    });
  });

  group('AssetTracker.findCacheDirSources()', () {
    test('discovers cache files using IoFilesystem', () async {
      await d.dir('pkg', [
        d.dir('.dart_tool', [
          d.dir('build', [
            d.dir('generated', [
              d.dir('pkg', [
                d.dir('lib', [d.file('a.g.dart', '// generated')]),
              ]),
              d.dir('other_pkg', [
                d.dir('lib', [d.file('b.g.dart', '// dep generated')]),
              ]),
            ]),
          ]),
        ]),
      ]).create();

      final buildPackages = BuildPackages.singlePackageBuild('pkg', [
        BuildPackage(
          name: 'pkg',
          path: p.join(d.sandbox, 'pkg'),
          languageVersion: LanguageVersion(2, 6),
          watch: true,
          isOutput: true,
        ),
      ]);
      final reader = ReaderWriter(buildPackages);
      final buildConfigs = await BuildConfigs.load(
        buildPackages: buildPackages,
        testingOverrides: TestingOverrides(
          defaultRootPackageSources: ['lib/**'].build(),
        ),
      );
      final tracker = AssetTracker(reader, buildPackages, buildConfigs);
      final cacheSources = await tracker.findCacheDirSources();

      expect(
        cacheSources,
        unorderedEquals({
          AssetId('pkg', 'lib/a.g.dart'),
          AssetId('other_pkg', 'lib/b.g.dart'),
        }),
      );
    });

    test('discovers cache files using InMemoryFilesystem', () async {
      final buildPackages = BuildPackages.singlePackageBuild('pkg', [
        BuildPackage.forTesting(name: 'pkg', watch: true, isOutput: true),
      ]);
      final readerWriter = InternalTestReaderWriter(outputRootPackage: 'pkg');
      await readerWriter.writeAsString(
        AssetId('pkg', 'lib/a.g.dart'),
        '// generated',
        hidden: true,
      );
      await readerWriter.writeAsString(
        AssetId('other_pkg', 'lib/b.g.dart'),
        '// dep generated',
        hidden: true,
      );

      final buildConfigs = await BuildConfigs.load(
        buildPackages: buildPackages,
        testingOverrides: TestingOverrides(
          defaultRootPackageSources: ['lib/**'].build(),
        ),
      );
      final tracker = AssetTracker(readerWriter, buildPackages, buildConfigs);
      final cacheSources = await tracker.findCacheDirSources();

      expect(
        cacheSources,
        unorderedEquals({
          AssetId('pkg', 'lib/a.g.dart'),
          AssetId('other_pkg', 'lib/b.g.dart'),
        }),
      );
    });
  });
}
