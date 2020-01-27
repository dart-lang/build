// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
@TestOn('vm')
import 'package:build/build.dart';
import 'package:build_runner_core/src/asset/finalized_reader.dart';
import 'package:build_runner_core/src/asset_graph/graph.dart';
import 'package:build_runner_core/src/asset_graph/node.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import 'package:_test_common/common.dart';

void main() {
  group('FinalizedReader', () {
    FinalizedReader reader;
    AssetNode notDeleted;
    AssetNode deleted;

    setUp(() async {
      var graph = await AssetGraph.build([], <AssetId>{}, <AssetId>{},
          buildPackageGraph({rootPackage('foo'): []}), null);

      notDeleted = makeAssetNode(
          'a|web/a.txt', [], computeDigest(AssetId('a', 'web/a.txt'), 'a'));
      deleted = makeAssetNode(
          'a|lib/b.txt', [], computeDigest(AssetId('a', 'lib/b.txt'), 'b'));
      deleted.deletedBy.add(deleted.id.addExtension('.post_anchor.1'));

      graph..add(notDeleted)..add(deleted);

      var delegate = InMemoryAssetReader();
      delegate.assets.addAll({notDeleted.id: [], deleted.id: []});

      reader = FinalizedReader(delegate, graph, [], 'a');
    });

    test('can not read deleted files', () async {
      expect(await reader.canRead(notDeleted.id), true);
      expect(await reader.canRead(deleted.id), false);
    });
  });
}
