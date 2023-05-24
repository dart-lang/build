// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:_test_common/common.dart';
import 'package:build/build.dart';
import 'package:build_runner/src/server/server.dart';
import 'package:build_runner_core/build_runner_core.dart';
import 'package:build_runner_core/src/asset_graph/graph.dart';
import 'package:build_runner_core/src/asset_graph/node.dart';
import 'package:build_runner_core/src/generate/options.dart';
import 'package:build_runner_core/src/package_graph/target_graph.dart';
import 'package:shelf/shelf.dart';
import 'package:test/fake.dart';
import 'package:test/test.dart';

void main() {
  late AssetHandler handler;
  late FinalizedReader reader;
  late InMemoryRunnerAssetReader delegate;
  late AssetGraph graph;

  setUp(() async {
    graph = await AssetGraph.build([], <AssetId>{}, <AssetId>{},
        buildPackageGraph({rootPackage('a'): []}), FakeAssetReader());
    delegate = InMemoryRunnerAssetReader();
    final packageGraph = buildPackageGraph({rootPackage('a'): []});
    reader = FinalizedReader(
        delegate,
        graph,
        await TargetGraph.forPackageGraph(packageGraph,
            defaultRootPackageSources: defaultRootPackageSources),
        [],
        'a');
    handler = AssetHandler(reader, 'a');
  });

  void addAsset(String id, String content, {bool deleted = false}) {
    var node = makeAssetNode(id, [], computeDigest(AssetId.parse(id), 'a'));
    if (deleted) {
      node.deletedBy.add(node.id.addExtension('.post_anchor.1'));
    }
    graph.add(node);
    delegate.cacheStringAsset(node.id, content);
  }

  test('can not read deleted nodes', () async {
    addAsset('a|web/index.html', 'content', deleted: true);
    var response = await handler.handle(
        Request('GET', Uri.parse('http://server.com/index.html')),
        rootDir: 'web');
    expect(response.statusCode, 404);
    expect(await response.readAsString(), 'Not Found');
  });

  test('can read from the root package', () async {
    addAsset('a|web/index.html', 'content');
    var response = await handler.handle(
        Request('GET', Uri.parse('http://server.com/index.html')),
        rootDir: 'web');
    expect(await response.readAsString(), 'content');
  });

  test('can read from dependencies', () async {
    addAsset('b|lib/b.dart', 'content');
    var response = await handler.handle(
        Request('GET', Uri.parse('http://server.com/packages/b/b.dart')),
        rootDir: 'web');
    expect(await response.readAsString(), 'content');
  });

  test('properly sets charset for dart content', () async {
    addAsset('b|lib/b.dart', 'content');
    var response = await handler.handle(
        Request('GET', Uri.parse('http://server.com/packages/b/b.dart')),
        rootDir: 'web');
    expect(response.headers['content-type'], contains('charset=utf-8'));
  });

  test('can read from dependencies nested under top-level dir', () async {
    addAsset('b|lib/b.dart', 'content');
    var response = await handler.handle(
        Request('GET', Uri.parse('http://server.com/packages/b/b.dart')),
        rootDir: 'web');
    expect(await response.readAsString(), 'content');
  });

  test('defaults to index.html if path is empty', () async {
    addAsset('a|web/index.html', 'content');
    var response = await handler.handle(
        Request('GET', Uri.parse('http://server.com/')),
        rootDir: 'web');
    expect(await response.readAsString(), 'content');
  });

  test('defaults to index.html if URI ends with slash', () async {
    addAsset('a|web/sub/index.html', 'content');
    var response = await handler.handle(
        Request('GET', Uri.parse('http://server.com/sub/')),
        rootDir: 'web');
    expect(await response.readAsString(), 'content');
  });

  test('does not default to index.html if URI does not end in slash', () async {
    addAsset('a|web/sub/index.html', 'content');
    var response = await handler.handle(
        Request('GET', Uri.parse('http://server.com/sub')),
        rootDir: 'web');
    expect(response.statusCode, 404);
  });

  test('Fails request for failed outputs', () async {
    graph.add(GeneratedAssetNode(
      AssetId('a', 'web/main.ddc.js'),
      builderOptionsId: AssetId('_\$fake', 'options_id'),
      phaseNumber: 0,
      state: NodeState.upToDate,
      isHidden: false,
      wasOutput: true,
      isFailure: true,
      primaryInput: AssetId('a', 'web/main.dart'),
    ));
    var response = await handler.handle(
        Request('GET', Uri.parse('http://server.com/main.ddc.js')),
        rootDir: 'web');
    expect(response.statusCode, HttpStatus.internalServerError);
  });

  test('Supports HEAD requests', () async {
    addAsset('a|web/index.html', 'content');
    var response = await handler.handle(
        Request('HEAD', Uri.parse('http://server.com/index.html')),
        rootDir: 'web');
    expect(response.contentLength, 0);
    expect(await response.readAsString(), '');
  });
}

class FakeAssetReader with Fake implements AssetReader {}
