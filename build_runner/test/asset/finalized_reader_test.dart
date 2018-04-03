// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
@TestOn('vm')
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:build/build.dart';
import 'package:build_runner/src/asset/finalized_reader.dart';
import 'package:build_runner/src/asset_graph/graph.dart';
import 'package:build_runner/src/asset_graph/node.dart';
import 'package:crypto/src/digest.dart';
import 'package:glob/glob.dart';
import 'package:test/test.dart';

import 'package:build_runner/build_runner.dart';

import '../common/common.dart';

final PackageGraph packageGraph =
    new PackageGraph.forPath('test/fixtures/basic_pkg');
final String newLine = Platform.isWindows ? '\r\n' : '\n';

class MockReader implements AssetReader {
  @override
  Future<bool> canRead(AssetId id) async => true;

  @override
  Future<Digest> digest(AssetId id) {
    throw 'Not implemented.';
  }

  @override
  Stream<AssetId> findAssets(Glob glob) {
    throw 'Not implemented.';
  }

  @override
  Future<List<int>> readAsBytes(AssetId id) {
    throw 'Not implemented.';
  }

  @override
  Future<String> readAsString(AssetId id, {Encoding encoding: utf8}) {
    throw 'Not implemented.';
  }
}

void main() {
  group('FinalizedReader', () {
    FinalizedReader reader;
    AssetNode notDeleted;
    AssetNode deleted;

    setUp(() async {
      var graph = await AssetGraph.build([], new Set(), new Set(),
          buildPackageGraph({rootPackage('foo'): []}), null);

      notDeleted = makeAssetNode('a|web/a.txt', [], computeDigest('a'));
      deleted = makeAssetNode('a|lib/b.txt', [], computeDigest('b'));
      deleted.isDeleted = true;

      graph.add(notDeleted);
      graph.add(deleted);

      reader = new FinalizedReader(new MockReader(), graph);
    });

    test('can not read deleted files', () async {
      expect(await reader.canRead(notDeleted.id), true);
      expect(await reader.canRead(deleted.id), false);
    });
  });
}
