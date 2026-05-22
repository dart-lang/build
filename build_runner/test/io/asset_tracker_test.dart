// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:build/build.dart';
import 'package:build_runner/src/build/asset_graph/graph.dart';
import 'package:build_runner/src/build_plan/build_configs.dart';
import 'package:build_runner/src/build_plan/build_package.dart';
import 'package:build_runner/src/build_plan/build_packages.dart';
import 'package:build_runner/src/build_plan/build_phases.dart';
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

    setUp(() async {
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
      buildState = BuildState.create(
        buildPhases: BuildPhases([]),
        buildPackages: buildPackages,
        sources: {aId},
      );
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
      final updates = await assetTracker.collectChanges(buildState);
      buildState.updateForNextBuild(BuildPhases([]), updates);
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

      expect(await assetTracker.collectChanges(buildState), {
        AssetId('a', 'web/a.txt'): ChangeType.MODIFY,
      });
    });

    test('Collects new files', () async {
      File(p.join(d.sandbox, 'a', 'web', 'b.txt')).writeAsStringSync('yo!');

      expect(await assetTracker.collectChanges(buildState), {
        AssetId('a', 'web/b.txt'): ChangeType.ADD,
      });
    });

    test('Collects deleted files', () async {
      File(p.join(d.sandbox, 'a', 'web', 'a.txt')).deleteSync();

      expect(await assetTracker.collectChanges(buildState), {
        AssetId('a', 'web/a.txt'): ChangeType.REMOVE,
      });
    });
  });
}
