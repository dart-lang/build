// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
@TestOn('vm')
import 'package:build_runner/src/asset/finalized_reader.dart';
import 'package:build_runner/src/asset_graph/graph.dart';
import 'package:build_runner/src/asset_graph/node.dart';
import 'package:build_runner/src/asset_graph/optional_output_tracker.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import 'package:test_common/common.dart';

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
      deleted.deletedBy.add(deleted.id.addExtension('.post_anchor.1'));

      graph.add(notDeleted);
      graph.add(deleted);

      var delegate = new InMemoryAssetReader();
      delegate.assets.addAll({notDeleted.id: [], deleted.id: []});

      reader = new FinalizedReader(
          delegate, graph, new OptionalOutputTracker(graph, [], []));
    });

    test('can not read deleted files', () async {
      expect(await reader.canRead(notDeleted.id), true);
      expect(await reader.canRead(deleted.id), false);
    });
  });
}
