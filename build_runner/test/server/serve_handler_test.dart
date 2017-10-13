// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import 'package:build/build.dart';
import 'package:build_runner/build_runner.dart';
import 'package:build_runner/src/generate/build_result.dart';
import 'package:build_runner/src/generate/watch_impl.dart';
import 'package:build_runner/src/server/server.dart';

import '../common/common.dart';

void main() {
  ServeHandler serveHandler;
  InMemoryRunnerAssetReader reader;

  setUp(() async {
    reader = new InMemoryRunnerAssetReader();
    var packageGraph =
        new PackageGraph.fromRoot(new PackageNode.noPubspec('a'));
    serveHandler =
        await createServeHandler(new MockWatchImpl(reader, packageGraph));
  });

  test('can get handlers for a subdirectory', () async {
    reader.cacheStringAsset(makeAssetId('a|web/index.html'), 'content');
    var response = await serveHandler.handlerFor('web')(
        new Request('GET', Uri.parse('http://server.com/index.html')));
    expect(await response.readAsString(), 'content');
  });

  test('throws if you pass a non-root directory', () {
    expect(() => serveHandler.handlerFor('web/sub'), throwsArgumentError);
  });
}

class MockWatchImpl implements WatchImpl {
  @override
  Future<BuildResult> get currentBuild => new Future.value(null);
  @override
  set currentBuild(_) => throw new UnsupportedError('unsupported!');

  @override
  get buildResults => throw new UnsupportedError('unsupported!');
  @override
  set buildResults(_) => throw new UnsupportedError('unsupported!');

  @override
  final PackageGraph packageGraph;

  @override
  final Future<AssetReader> reader;

  MockWatchImpl(AssetReader reader, this.packageGraph)
      : this.reader = new Future.value(reader);
}
