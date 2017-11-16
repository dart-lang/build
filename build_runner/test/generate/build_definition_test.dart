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
      addTearDown(() async => await file.exists() ? await file.delete() : null);
    }

    Future<Null> deleteFile(String path) async {
      var file = new File(p.join(pkgARoot, path));
      expect(await file.exists(), isTrue);
      await file.delete();
    }

    Future<Null> modifyFile(String path, String contents) async {
      var file = new File(p.join(pkgARoot, path));
      expect(await file.exists(), isTrue);
      await file.writeAsString(contents);
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

    tearDown(() async {
      await options.logListener.cancel();
    });

    group('updates the asset graph', () {
      test('for deleted source and generated nodes', () async {
        await createFile(p.join('lib', 'a.txt'), 'a');
        await createFile(p.join('lib', 'b.txt'), 'b');
        var buildActions = [new BuildAction(new CopyBuilder(), 'a')];

        var originalAssetGraph = await AssetGraph.build(
            buildActions,
            [makeAssetId('a|lib/a.txt'), makeAssetId('a|lib/b.txt')].toSet(),
            'a',
            options.reader);
        var generatedAId = makeAssetId('a|lib/a.txt.copy');
        var generatedANode =
            originalAssetGraph.get(generatedAId) as GeneratedAssetNode;
        generatedANode.wasOutput = true;
        generatedANode.needsUpdate = false;

        await createFile(
            assetGraphPath, JSON.encode(originalAssetGraph.serialize()));

        await deleteFile(p.join('lib', 'b.txt'));
        var buildDefinition =
            await BuildDefinition.prepareWorkspace(options, buildActions);
        var newAssetGraph = buildDefinition.assetGraph;

        generatedANode = newAssetGraph.get(generatedAId) as GeneratedAssetNode;
        expect(generatedANode, isNotNull);
        expect(generatedANode.needsUpdate, isTrue);

        expect(newAssetGraph.contains(makeAssetId('a|lib/b.txt')), isFalse);
        expect(
            newAssetGraph.contains(makeAssetId('a|lib/b.txt.copy')), isFalse);
      });

      test('for new sources and generated nodes', () async {
        var buildActions = [new BuildAction(new CopyBuilder(), 'a')];

        var originalAssetGraph = await AssetGraph.build(
            buildActions, <AssetId>[].toSet(), 'a', options.reader);

        await createFile(
            assetGraphPath, JSON.encode(originalAssetGraph.serialize()));

        await createFile(p.join('lib', 'a.txt'), 'a');
        var buildDefinition =
            await BuildDefinition.prepareWorkspace(options, buildActions);
        var newAssetGraph = buildDefinition.assetGraph;

        expect(newAssetGraph.contains(makeAssetId('a|lib/a.txt')), isTrue);

        var generatedANode = newAssetGraph.get(makeAssetId('a|lib/a.txt.copy'))
            as GeneratedAssetNode;
        expect(generatedANode, isNotNull);
        expect(generatedANode.needsUpdate, isTrue);
      });

      test('for changed sources', () async {
        await createFile(p.join('lib', 'a.txt'), 'a');
        var buildActions = [new BuildAction(new CopyBuilder(), 'a')];

        var originalAssetGraph = await AssetGraph.build(buildActions,
            [makeAssetId('a|lib/a.txt')].toSet(), 'a', options.reader);

        await createFile(
            assetGraphPath, JSON.encode(originalAssetGraph.serialize()));

        await modifyFile(p.join('lib', 'a.txt'), 'b');
        var buildDefinition =
            await BuildDefinition.prepareWorkspace(options, buildActions);
        var newAssetGraph = buildDefinition.assetGraph;

        var generatedANode = newAssetGraph.get(makeAssetId('a|lib/a.txt.copy'))
            as GeneratedAssetNode;
        expect(generatedANode, isNotNull);
        expect(generatedANode.needsUpdate, isTrue);
      });

      test('retains non-output generated nodes', () async {
        await createFile(p.join('lib', 'test.txt'), 'a');
        var buildActions = [
          new BuildAction(new OverDeclaringCopyBuilder(), 'a')
        ];

        var originalAssetGraph = await AssetGraph.build(buildActions,
            [makeAssetId('a|lib/test.txt')].toSet(), 'a', options.reader);
        var generatedSrcId = makeAssetId('a|lib/test.txt.copy');
        var generatedNode =
            originalAssetGraph.get(generatedSrcId) as GeneratedAssetNode;
        generatedNode.wasOutput = false;

        await createFile(
            assetGraphPath, JSON.encode(originalAssetGraph.serialize()));

        var buildDefinition =
            await BuildDefinition.prepareWorkspace(options, buildActions);
        expect(buildDefinition.assetGraph.contains(generatedSrcId), isTrue);
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

        var buildDefinition =
            await BuildDefinition.prepareWorkspace(options, buildActions);

        expect(buildDefinition.assetGraph.contains(generatedId), isFalse);
      });

      test('includes generated entrypoint', () async {
        var entryPoint =
            new AssetId('a', p.url.join(entryPointDir, 'build.dart'));
        var buildDefinition =
            await BuildDefinition.prepareWorkspace(options, []);
        expect(buildDefinition.assetGraph.contains(entryPoint), isTrue);
      });

      test('does not run Builders on generated entrypoint', () async {
        var entryPoint =
            new AssetId('a', p.url.join(entryPointDir, 'build.dart'));
        var buildActions = [new BuildAction(new CopyBuilder(), 'a')];
        var buildDefinition =
            await BuildDefinition.prepareWorkspace(options, buildActions);
        expect(
            buildDefinition.assetGraph
                .contains(entryPoint.addExtension('.copy')),
            isFalse);
      });
    });

    test('invalidates the graph if the build actions change', () async {
      // Gets rid of console spam during tests, we are setting up a new options
      // object.
      await options.logListener.cancel();

      var buildActions = [new BuildAction(new CopyBuilder(), 'a')];
      var logs = <LogRecord>[];
      options = new BuildOptions(
          packageGraph: options.packageGraph,
          logLevel: Level.WARNING,
          writeToCache: true,
          skipBuildScriptCheck: true,
          onLog: logs.add);

      var originalAssetGraph = await AssetGraph.build(
          buildActions, <AssetId>[].toSet(), 'a', options.reader);

      await createFile(
          assetGraphPath, JSON.encode(originalAssetGraph.serialize()));

      buildActions
          .add(new BuildAction(new CopyBuilder(), 'a', inputs: ['.copy']));
      logs.clear();

      var buildDefinition =
          await BuildDefinition.prepareWorkspace(options, buildActions);
      expect(
          logs.any(
            (log) =>
                log.level == Level.WARNING &&
                log.message.contains('build actions have changed'),
          ),
          isTrue);

      var newAssetGraph = buildDefinition.assetGraph;
      expect(originalAssetGraph.buildActionsDigest,
          isNot(newAssetGraph.buildActionsDigest));
    });
  });
}
