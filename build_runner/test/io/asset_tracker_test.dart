// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:build/build.dart';
import 'package:build_runner/src/build/build_state/build_state.dart';
import 'package:build_runner/src/build/build_state/build_step_id.dart';
import 'package:build_runner/src/build_plan/build_configs.dart';
import 'package:build_runner/src/build_plan/build_package.dart';
import 'package:build_runner/src/build_plan/build_packages.dart';
import 'package:build_runner/src/build_plan/build_phases.dart';
import 'package:build_runner/src/build_plan/build_step_plan.dart';
import 'package:build_runner/src/build_plan/phase.dart';
import 'package:build_runner/src/build_plan/testing_overrides.dart';
import 'package:build_runner/src/io/asset_tracker.dart';
import 'package:build_runner/src/io/reader_writer.dart';
import 'package:built_collection/built_collection.dart';
import 'package:package_config/package_config.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;
import 'package:watcher/watcher.dart';

void main() {
  group('AssetTracker.collectChanges()', () {
    late AssetTracker assetTracker;
    late BuildState buildState;
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
      buildState = BuildState.create(sources: {aId});
      // Assign a digest so the source is recognized as having been used.
      final digest = await reader.digest(aId);
      buildState.updateSourceDigest(aId, digest);

      final buildConfigs = await BuildConfigs.load(
        buildPackages: buildPackages,
        testingOverrides: TestingOverrides(
          defaultRootPackageSources: ['web/**'].build(),
        ),
      );
      assetTracker = AssetTracker(reader, buildPackages, buildConfigs);
      final updates = await assetTracker.collectChanges(
        buildState: buildState,
        buildStepPlan: buildStepPlan,
      );
      buildState.updateForNextBuild(buildStepPlan, updates);
      // We should see no changes initially other than new sdk sources
      expect(
        updates..removeWhere(
          (id, type) => id.package == r'$sdk' && type == ChangeType.ADD,
        ),
        isEmpty,
      );
    });

    test('Collects file edits', () async {
      File(p.join(d.sandbox, 'a', 'web', 'a.txt')).writeAsStringSync('goodbye');

      expect(
        await assetTracker.collectChanges(
          buildState: buildState,
          buildStepPlan: buildStepPlan,
        ),
        {AssetId('a', 'web/a.txt'): ChangeType.MODIFY},
      );
    });

    test('Collects new files', () async {
      File(p.join(d.sandbox, 'a', 'web', 'b.txt')).writeAsStringSync('yo!');

      expect(
        await assetTracker.collectChanges(
          buildState: buildState,
          buildStepPlan: buildStepPlan,
        ),
        {AssetId('a', 'web/b.txt'): ChangeType.ADD},
      );
    });

    test('Collects deleted files', () async {
      File(p.join(d.sandbox, 'a', 'web', 'a.txt')).deleteSync();

      expect(
        await assetTracker.collectChanges(
          buildState: buildState,
          buildStepPlan: buildStepPlan,
        ),
        {AssetId('a', 'web/a.txt'): ChangeType.REMOVE},
      );
    });

    test('Collects deleted declared outputs', () async {
      // Create a buildState with no sources (so web/a.txt is not in sources).
      final emptyBuildState = BuildState.create(sources: const {});

      // Delete the file from disk so it's actually missing.
      File(p.join(d.sandbox, 'a', 'web', 'a.txt')).deleteSync();

      final outputId = AssetId('a', 'web/a.txt');
      final buildStepId = BuildStepId(
        primaryInput: AssetId('a', 'web/a.dart'),
        phaseNumber: 0,
      );

      final planWithOutput = BuildStepPlan(
        (BuildStepPlanBuilder b) =>
            b
              ..buildPhases = BuildPhases(const <InBuildPhase>[])
              ..buildStepsByDeclaredOutput.addAll({outputId: buildStepId}),
      );

      final changes = await assetTracker.collectChanges(
        buildState: emptyBuildState,
        buildStepPlan: planWithOutput,
      );
      changes.removeWhere((id, type) => id.package == r'$sdk');
      expect(changes, {outputId: ChangeType.REMOVE});
    });
  });
}
