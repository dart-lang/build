// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import 'package:build_runner/src/asset/finalized_reader.dart';
import 'package:build_runner/src/asset_graph/graph.dart';
import 'package:build_runner/src/asset_graph/node.dart';
import 'package:build_runner/src/asset_graph/optional_output_tracker.dart';
import 'package:build_runner/src/server/server.dart';

import '../common/common.dart';

void main() {
  AssetHandler handler;
  FinalizedReader reader;
  InMemoryRunnerAssetReader delegate;
  AssetGraph graph;

  setUp(() async {
    graph = await AssetGraph.build([], new Set(), new Set(),
        buildPackageGraph({rootPackage('foo'): []}), null);
    delegate = new InMemoryRunnerAssetReader();
    reader = new FinalizedReader(
        delegate, graph, new OptionalOutputTracker(graph, []));
    handler = new AssetHandler(reader, 'a');
  });

  void _addAsset(String id, String content, {bool deleted: false}) {
    var node = makeAssetNode(id, [], computeDigest('a'));
    if (deleted) {
      node.deletedBy.add(node.id.addExtension('.post_anchor.1'));
    }
    graph.add(node);
    delegate.cacheStringAsset(node.id, content);
  }

  test('can not read deleted nodes', () async {
    _addAsset('a|web/index.html', 'content', deleted: true);
    var response = await handler.handle(
        new Request('GET', Uri.parse('http://server.com/index.html')), 'web');
    expect(response.statusCode, 404);
    expect(await response.readAsString(), 'Not Found');
  });

  test('can read from the root package', () async {
    _addAsset('a|web/index.html', 'content');
    var response = await handler.handle(
        new Request('GET', Uri.parse('http://server.com/index.html')), 'web');
    expect(await response.readAsString(), 'content');
  });

  test('can read from dependencies', () async {
    _addAsset('b|lib/b.dart', 'content');
    var response = await handler.handle(
        new Request('GET', Uri.parse('http://server.com/packages/b/b.dart')),
        'web');
    expect(await response.readAsString(), 'content');
  });

  test('can read from dependencies nested under top-level dir', () async {
    _addAsset('b|lib/b.dart', 'content');
    var response = await handler.handle(
        new Request('GET', Uri.parse('http://server.com/packages/b/b.dart')),
        'web');
    expect(await response.readAsString(), 'content');
  });

  test('defaults to index.html if path is empty', () async {
    _addAsset('a|web/index.html', 'content');
    var response = await handler.handle(
        new Request('GET', Uri.parse('http://server.com/')), 'web');
    expect(await response.readAsString(), 'content');
  });

  test('defaults to index.html if URI ends with slash', () async {
    _addAsset('a|web/sub/index.html', 'content');
    var response = await handler.handle(
        new Request('GET', Uri.parse('http://server.com/sub/')), 'web');
    expect(await response.readAsString(), 'content');
  });

  test('does not default to index.html if URI does not end in slash', () async {
    _addAsset('a|web/sub/index.html', 'content');
    var response = await handler.handle(
        new Request('GET', Uri.parse('http://server.com/sub')), 'web');
    expect(response.statusCode, 404);
  });

  test('Fails request for failed outputs', () async {
    graph.add(new GeneratedAssetNode(
      makeAssetId('a|web/main.ddc.js'),
      builderOptionsId: null,
      phaseNumber: null,
      state: GeneratedNodeState.upToDate,
      isHidden: false,
      wasOutput: true,
      isFailure: true,
      primaryInput: null,
    ));
    var response = await handler.handle(
        new Request('GET', Uri.parse('http://server.com/main.ddc.js')), 'web');
    expect(response.statusCode, HttpStatus.INTERNAL_SERVER_ERROR);
  });
}
