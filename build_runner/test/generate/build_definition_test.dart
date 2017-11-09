// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:build/build.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;
import 'package:watcher/watcher.dart';

import 'package:build_runner/build_runner.dart';
import 'package:build_runner/src/asset_graph/graph.dart';
import 'package:build_runner/src/asset_graph/node.dart';
import 'package:build_runner/src/generate/build_definition.dart';
import 'package:build_runner/src/generate/options.dart';
import 'package:build_runner/src/package_graph/package_graph.dart';
import 'package:build_runner/src/util/constants.dart';

import '../common/common.dart';

main() {
  group('BuildDefinition.load', () {
    BuildOptions options;
    String pkgARoot;

    Future<Null> createFile(String path, String contents) async {
      var file = new File(p.join(pkgARoot, path));
      expect(await file.exists(), isFalse);
      await file.create(recursive: true);
      await file.writeAsString(contents);
      addTearDown(() => file.delete());
    }

    setUp(() async {
      await d.dir(
        'pkg_a',
        [
          await pubspec('a'),
          d.file('.packages', '\na:./lib/'),
          d.dir('.dart_tool', [
            d.dir('build', [
              d.dir('entrypoint', [d.file('build.dart', '// builds!')])
            ])
          ]),
          d.dir('lib'),
        ],
      ).create();
      pkgARoot = p.join(d.sandbox, 'pkg_a');
      var packageGraph = new PackageGraph.forPath(pkgARoot);
      options = new BuildOptions(
          packageGraph: packageGraph,
          logLevel: Level.OFF,
          writeToCache: true,
          skipBuildScriptCheck: true);
    });

    group('updates', () {
      test('contains deleted outputs as remove events', () async {
        await createFile(p.join('lib', 'test.txt'), 'a');
        var buildActions = [new BuildAction(new CopyBuilder(), 'a')];

        var assetGraph = await AssetGraph.build(buildActions,
            [makeAssetId('a|lib/test.txt')].toSet(), 'a', options.reader);
        var generatedSrcId = makeAssetId('a|lib/test.txt.copy');
        var generatedNode =
            assetGraph.get(generatedSrcId) as GeneratedAssetNode;
        generatedNode.wasOutput = true;

        await createFile(assetGraphPath, JSON.encode(assetGraph.serialize()));

        var buildDefinition = await BuildDefinition.load(options, buildActions);
        expect(buildDefinition.updates, contains(generatedSrcId));
        expect(buildDefinition.updates[generatedSrcId], ChangeType.REMOVE);
      });

      test('ignores non-output generated nodes', () async {
        await createFile(p.join('lib', 'test.txt'), 'a');
        var buildActions = [
          new BuildAction(new OverDeclaringCopyBuilder(), 'a')
        ];

        var assetGraph = await AssetGraph.build(buildActions,
            [makeAssetId('a|lib/test.txt')].toSet(), 'a', options.reader);
        var generatedSrcId = makeAssetId('a|lib/test.txt.copy');
        var generatedNode =
            assetGraph.get(generatedSrcId) as GeneratedAssetNode;
        generatedNode.wasOutput = false;

        await createFile(assetGraphPath, JSON.encode(assetGraph.serialize()));

        var buildDefinition = await BuildDefinition.load(options, buildActions);
        expect(buildDefinition.updates, isNot(contains(generatedSrcId)));
      });
    });

    group('assetGraph', () {
      test('doesn\'t capture unrecognized cacheDir files as inputs', () async {
        var generatedId = new AssetId(
            'a', p.url.join(generatedOutputDirectory, 'a', 'lib', 'test.txt'));
        await createFile(generatedId.path, 'a');
        var buildActions = [new BuildAction(new CopyBuilder(), 'a')];

        var assetGraph = await AssetGraph.build(
            buildActions, new Set<AssetId>(), 'a', options.reader);
        expect(assetGraph.allNodes, isEmpty);

        await createFile(assetGraphPath, JSON.encode(assetGraph.serialize()));

        var buildDefinition = await BuildDefinition.load(options, buildActions);
        expect(buildDefinition.updates, isNot(contains(generatedId)));
        expect(buildDefinition.assetGraph.contains(generatedId), isFalse);
      });

      test('includes generated entrypoint', () async {
        var entryPoint =
            new AssetId('a', p.url.join(entryPointDir, 'build.dart'));
        var buildDefinition = await BuildDefinition.load(options, []);
        expect(buildDefinition.assetGraph.contains(entryPoint), isTrue);
      });

      test('does not run Builders on generated entrypoint', () async {
        var entryPoint =
            new AssetId('a', p.url.join(entryPointDir, 'build.dart'));
        var buildActions = [new BuildAction(new CopyBuilder(), 'a')];
        var buildDefinition = await BuildDefinition.load(options, buildActions);
        expect(
            buildDefinition.assetGraph
                .contains(entryPoint.addExtension('.copy')),
            isFalse);
      });
    });
  });
}
