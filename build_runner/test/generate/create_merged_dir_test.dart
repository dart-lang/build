// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'package:build_runner/src/asset_graph/graph.dart';
import 'package:build_runner/src/asset_graph/node.dart';
import 'package:build_runner/src/generate/create_merged_dir.dart';
import 'package:build_runner/src/generate/phase.dart';

import '../common/common.dart';
import '../common/package_graphs.dart';
import '../common/test_environment.dart';

main() {
  group('createMergedDir', () {
    AssetGraph graph;
    final actions = [
      new BuilderBuildAction(
          new TestBuilder(
              buildExtensions: appendExtension('.copy', from: '.txt')),
          'a'),
      new BuilderBuildAction(
          new TestBuilder(
              buildExtensions: appendExtension('.copy', from: '.txt')),
          'b')
    ];
    final sources = {
      makeAssetId('a|lib/a.txt'): 'a',
      makeAssetId('a|web/b.txt'): 'b',
      makeAssetId('b|lib/c.txt'): 'c',
    };
    final packageGraph = buildPackageGraph({
      rootPackage('a'): ['b'],
      package('b'): []
    });
    Directory tmpDir;
    TestBuildEnvironment environment;
    InMemoryRunnerAssetReader assetReader;

    setUp(() async {
      assetReader = new InMemoryRunnerAssetReader(sources);
      environment = new TestBuildEnvironment(reader: assetReader);
      graph = await AssetGraph.build(actions, sources.keys.toSet(),
          new Set<AssetId>(), packageGraph, assetReader);
      for (var id in graph.outputs) {
        var node = graph.get(id) as GeneratedAssetNode;
        node.state = GeneratedNodeState.upToDate;
        node.wasOutput = true;
        assetReader.cacheStringAsset(id, sources[node.primaryInput]);
      }
      tmpDir = await Directory.systemTemp.createTemp('build_tests');
    });

    tearDown(() async {
      await tmpDir.delete(recursive: true);
    });

    test('creates a valid merged output directory', () async {
      var success = await createMergedOutputDir(
          tmpDir.path, graph, packageGraph, assetReader, environment, actions);
      expect(success, isTrue);

      _expectAllFiles(tmpDir);
    });

    test('doesnt write files that werent output', () async {
      var node =
          graph.get(new AssetId('b', 'lib/c.txt.copy')) as GeneratedAssetNode;
      node.wasOutput = false;

      var success = await createMergedOutputDir(
          tmpDir.path, graph, packageGraph, assetReader, environment, actions);
      expect(success, isTrue);

      var file = new File(p.join(tmpDir.path, 'packages/b/c.txt.copy'));
      expect(file.existsSync(), isFalse);
    });

    group('existing output dir handling', () {
      File garbageFile;
      setUp(() {
        garbageFile = new File(p.join(tmpDir.path, 'garbage_file.txt'));
        garbageFile.createSync();
      });

      test('fails in non-interactive mode', () async {
        environment =
            new TestBuildEnvironment(reader: assetReader, throwOnPrompt: true);
        var success = await createMergedOutputDir(tmpDir.path, graph,
            packageGraph, assetReader, environment, actions);
        expect(success, isFalse);
      });

      test('can skip creating the directory', () async {
        environment.nextPromptResponse = 0;
        var success = await createMergedOutputDir(tmpDir.path, graph,
            packageGraph, assetReader, environment, actions);
        expect(success, isFalse,
            reason: 'Skipping creation of the directory should be considered a '
                'failure.');

        expect(garbageFile.existsSync(), isTrue,
            reason: 'Should not delete existing files.');
        var file = new File(p.join(tmpDir.path, 'web/b.txt'));
        expect(file.existsSync(), isFalse,
            reason: 'Should not copy any files.');
      });

      test('can delete the entire existing directory', () async {
        environment.nextPromptResponse = 1;
        var success = await createMergedOutputDir(tmpDir.path, graph,
            packageGraph, assetReader, environment, actions);
        expect(success, isTrue);

        expect(garbageFile.existsSync(), isFalse);
        _expectAllFiles(tmpDir);
      });

      test('can merge into the existing directory', () async {
        environment.nextPromptResponse = 2;
        var success = await createMergedOutputDir(tmpDir.path, graph,
            packageGraph, assetReader, environment, actions);
        expect(success, isTrue);

        expect(garbageFile.existsSync(), isTrue,
            reason: 'Existing files should be left alone.');
        _expectAllFiles(tmpDir);
      });
    });
  });
}

void _expectAllFiles(Directory dir) {
  var expectedFiles = <String, dynamic>{
    'packages/a/a.txt': 'a',
    'packages/a/a.txt.copy': 'a',
    'packages/b/c.txt': 'c',
    'packages/b/c.txt.copy': 'c',
    'web/b.txt': 'b',
    'web/b.txt.copy': 'b',
    'web/.packages': '''
a:packages/a/\r
b:packages/b/\r
\$sdk:packages/\$sdk/''',
  };
  expectedFiles['.build.manifest'] =
      allOf(expectedFiles.keys.map(contains).toList());
  expectedFiles.forEach((path, content) {
    var file = new File(p.join(dir.path, path));
    expect(file.existsSync(), isTrue, reason: 'Missing file at $path.');
    expect(file.readAsStringSync(), content,
        reason: 'Incorrect content for file at $path');
  });
}
