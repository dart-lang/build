// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:build/build.dart';
import 'package:build_runner_core/build_runner_core.dart';
import 'package:build_runner_core/src/asset_graph/graph.dart';
import 'package:build_runner_core/src/generate/build_definition.dart';
import 'package:build_runner_core/src/package_graph/target_graph.dart';
import 'package:package_config/package_config.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;
import 'package:watcher/watcher.dart';

void main() {
  group('AssetTracker.collectChanges()', () {
    late AssetTracker assetTracker;
    late AssetGraph assetGraph;

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
      var packageGraph = PackageGraph.fromRoot(
        PackageNode(
          'a',
          p.join(d.sandbox, 'a'),
          DependencyType.path,
          LanguageVersion(2, 6),
          isRoot: true,
        ),
      );
      var reader = FileBasedAssetReader(packageGraph);
      var aId = AssetId('a', 'web/a.txt');
      assetGraph = await AssetGraph.build(
        [],
        {aId},
        <AssetId>{},
        packageGraph,
        reader,
      );
      // We need to pre-emptively assign a digest so we determine that the
      // node is "interesting".
      assetGraph.get(aId)!.lastKnownDigest = await reader.digest(aId);

      var targetGraph = await TargetGraph.forPackageGraph(
        packageGraph,
        defaultRootPackageSources: ['web/**'],
      );
      assetTracker = AssetTracker(reader, targetGraph);
      var updates = await assetTracker.collectChanges(assetGraph);
      await assetGraph.updateAndInvalidate(
        [],
        updates,
        'a',
        (_) async {},
        reader,
      );
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

      expect(await assetTracker.collectChanges(assetGraph), {
        AssetId('a', 'web/a.txt'): ChangeType.MODIFY,
      });
    });

    test('Collects new files', () async {
      File(p.join(d.sandbox, 'a', 'web', 'b.txt')).writeAsStringSync('yo!');

      expect(await assetTracker.collectChanges(assetGraph), {
        AssetId('a', 'web/b.txt'): ChangeType.ADD,
      });
    });

    test('Collects deleted files', () async {
      File(p.join(d.sandbox, 'a', 'web', 'a.txt')).deleteSync();

      expect(await assetTracker.collectChanges(assetGraph), {
        AssetId('a', 'web/a.txt'): ChangeType.REMOVE,
      });
    });
  });
}
