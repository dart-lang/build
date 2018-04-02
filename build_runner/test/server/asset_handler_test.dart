// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import 'package:build_runner/src/server/server.dart';
import 'package:build_runner/src/asset_graph/graph.dart';
import 'package:build_runner/src/asset_graph/node.dart';

import '../common/common.dart';

void main() {
  AssetHandler handler;
  InMemoryRunnerAssetReader reader;
  AssetGraph assetGraph;

  setUp(() async {
    reader = new InMemoryRunnerAssetReader();
    final packageGraph = buildPackageGraph({rootPackage('a'): []});
    assetGraph =
        await AssetGraph.build([], new Set(), new Set(), packageGraph, reader);
    handler = new AssetHandler(reader, 'a', assetGraph);
  });

  test('can read from the root package', () async {
    reader.cacheStringAsset(makeAssetId('a|web/index.html'), 'content');
    var response = await handler.handle(
        new Request('GET', Uri.parse('http://server.com/index.html')), 'web');
    expect(await response.readAsString(), 'content');
  });

  test('can read from dependencies', () async {
    reader.cacheStringAsset(makeAssetId('b|lib/b.dart'), 'content');
    var response = await handler.handle(
        new Request('GET', Uri.parse('http://server.com/packages/b/b.dart')),
        'web');
    expect(await response.readAsString(), 'content');
  });

  test('can read from dependencies nested under top-level dir', () async {
    reader.cacheStringAsset(makeAssetId('b|lib/b.dart'), 'content');
    var response = await handler.handle(
        new Request('GET', Uri.parse('http://server.com/packages/b/b.dart')),
        'web');
    expect(await response.readAsString(), 'content');
  });

  test('defaults to index.html if path is empty', () async {
    reader.cacheStringAsset(makeAssetId('a|web/index.html'), 'content');
    var response = await handler.handle(
        new Request('GET', Uri.parse('http://server.com/')), 'web');
    expect(await response.readAsString(), 'content');
  });

  test('defaults to index.html if URI ends with slash', () async {
    reader.cacheStringAsset(makeAssetId('a|web/sub/index.html'), 'content');
    var response = await handler.handle(
        new Request('GET', Uri.parse('http://server.com/sub/')), 'web');
    expect(await response.readAsString(), 'content');
  });

  test('does not default to index.html if URI does not end in slash', () async {
    reader.cacheStringAsset(makeAssetId('a|web/sub/index.html'), 'content');
    var response = await handler.handle(
        new Request('GET', Uri.parse('http://server.com/sub')), 'web');
    expect(response.statusCode, 404);
  });

  test('Fails request for failed outputs', () async {
    assetGraph.add(new GeneratedAssetNode(
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
