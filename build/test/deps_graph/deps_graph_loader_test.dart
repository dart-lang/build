// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/src/asset/id.dart';
import 'package:build/src/deps_graph/deps_graph_loader.dart';
import 'package:build/src/deps_graph/deps_node.dart';
import 'package:build/src/deps_graph/deps_node_loader.dart';
import 'package:test/test.dart';

void main() {
  group('DepsGraphLoader', () {
    group('no generated nodes', () {
      test('single missing node', () async {
        final nodeLoader = TestDepsNodeLoader(0, [
          DepsNode.missingSource(AssetId('p1', 'l1')),
        ]);
        final loader = DepsGraphLoader();
        await loader.load(nodeLoader, AssetId('p1', 'l1'));
        expect(await loader.transitiveDepsOf(nodeLoader, AssetId('p1', 'l1')), {
          AssetId('p1', 'l1'),
        });
      });

      test('single present node', () async {
        final nodeLoader = TestDepsNodeLoader(0, [
          DepsNode.source(AssetId('p1', 'l1'), {}),
        ]);
        final loader = DepsGraphLoader();
        await loader.load(nodeLoader, AssetId('p1', 'l1'));
        expect(await loader.transitiveDepsOf(nodeLoader, AssetId('p1', 'l1')), {
          AssetId('p1', 'l1'),
        });
      });

      test('node with one dep', () async {
        final nodeLoader = TestDepsNodeLoader(0, [
          DepsNode.source(AssetId('p1', 'l1'), {AssetId('p1', 'l2')}),
          DepsNode.source(AssetId('p1', 'l2'), {}),
        ]);
        final loader = DepsGraphLoader();
        await loader.load(nodeLoader, AssetId('p1', 'l1'));
        expect(await loader.transitiveDepsOf(nodeLoader, AssetId('p1', 'l1')), {
          AssetId('p1', 'l1'),
          AssetId('p1', 'l2'),
        });
      });

      test('seven node tree', () async {
        final nodeLoader = TestDepsNodeLoader(0, [
          DepsNode.source(AssetId('p1', 'l1'), {
            AssetId('p1', 'l2'),
            AssetId('p1', 'l3'),
          }),
          DepsNode.source(AssetId('p1', 'l2'), {
            AssetId('p1', 'l4'),
            AssetId('p1', 'l5'),
          }),
          DepsNode.source(AssetId('p1', 'l3'), {
            AssetId('p1', 'l6'),
            AssetId('p1', 'l7'),
          }),
          DepsNode.source(AssetId('p1', 'l4'), {}),
          DepsNode.source(AssetId('p1', 'l5'), {}),
          DepsNode.source(AssetId('p1', 'l6'), {}),
          DepsNode.source(AssetId('p1', 'l7'), {}),
        ]);
        final loader = DepsGraphLoader();
        await loader.load(nodeLoader, AssetId('p1', 'l1'));
        expect(await loader.transitiveDepsOf(nodeLoader, AssetId('p1', 'l1')), {
          AssetId('p1', 'l1'),
          AssetId('p1', 'l2'),
          AssetId('p1', 'l3'),
          AssetId('p1', 'l4'),
          AssetId('p1', 'l5'),
          AssetId('p1', 'l6'),
          AssetId('p1', 'l7'),
        });
      });

      test('four node diamond', () async {
        final nodeLoader = TestDepsNodeLoader(0, [
          DepsNode.source(AssetId('p1', 'l1'), {
            AssetId('p1', 'l2'),
            AssetId('p1', 'l3'),
          }),
          DepsNode.source(AssetId('p1', 'l2'), {AssetId('p1', 'l4')}),
          DepsNode.source(AssetId('p1', 'l3'), {AssetId('p1', 'l4')}),
          DepsNode.source(AssetId('p1', 'l4'), {}),
        ]);
        final loader = DepsGraphLoader();
        await loader.load(nodeLoader, AssetId('p1', 'l1'));
        expect(await loader.transitiveDepsOf(nodeLoader, AssetId('p1', 'l1')), {
          AssetId('p1', 'l1'),
          AssetId('p1', 'l2'),
          AssetId('p1', 'l3'),
          AssetId('p1', 'l4'),
        });
      });

      test('two node cycle', () async {
        final nodeLoader = TestDepsNodeLoader(0, [
          DepsNode.source(AssetId('p1', 'l1'), {AssetId('p1', 'l2')}),
          DepsNode.source(AssetId('p1', 'l2'), {AssetId('p1', 'l1')}),
        ]);
        final loader = DepsGraphLoader();
        await loader.load(nodeLoader, AssetId('p1', 'l1'));
        expect(await loader.transitiveDepsOf(nodeLoader, AssetId('p1', 'l1')), {
          AssetId('p1', 'l1'),
          AssetId('p1', 'l2'),
        });
      });

      test('two node cycle excluding entrypoint', () async {
        final nodeLoader = TestDepsNodeLoader(0, [
          DepsNode.source(AssetId('p1', 'l1'), {AssetId('p1', 'l2')}),
          DepsNode.source(AssetId('p1', 'l2'), {AssetId('p1', 'l3')}),
          DepsNode.source(AssetId('p1', 'l3'), {AssetId('p1', 'l2')}),
        ]);
        final loader = DepsGraphLoader();
        await loader.load(nodeLoader, AssetId('p1', 'l1'));
        expect(await loader.transitiveDepsOf(nodeLoader, AssetId('p1', 'l1')), {
          AssetId('p1', 'l1'),
          AssetId('p1', 'l2'),
          AssetId('p1', 'l3'),
        });
      });
    });
  });

  group('with generated nodes', () {
    test('single generated node', () async {
      final nodeLoader0 = TestDepsNodeLoader(0, [
        DepsNode.futureGenerated(AssetId('p1', 'l1'), 1),
      ]);
      final nodeLoader2 = TestDepsNodeLoader(2, [
        DepsNode.generated(AssetId('p1', 'l1'), 1, {}),
      ]);
      final loader = DepsGraphLoader();
      await loader.load(nodeLoader2, AssetId('p1', 'l1'));

      // It's a dependency irrespective of the phase.
      expect(await loader.transitiveDepsOf(nodeLoader0, AssetId('p1', 'l1')), {
        AssetId('p1', 'l1'),
      });
      expect(await loader.transitiveDepsOf(nodeLoader2, AssetId('p1', 'l1')), {
        AssetId('p1', 'l1'),
      });
    });

    test('sequence of three nodes', () async {
      final nodeLoader1 = TestDepsNodeLoader(1, [
        DepsNode.futureGenerated(AssetId('p1', 'l1'), 1),
        DepsNode.futureGenerated(AssetId('p1', 'l2'), 2),
        DepsNode.futureGenerated(AssetId('p1', 'l3'), 3),
      ]);
      final nodeLoader2 = TestDepsNodeLoader(2, [
        DepsNode.generated(AssetId('p1', 'l1'), 1, {AssetId('p1', 'l2')}),
        DepsNode.futureGenerated(AssetId('p1', 'l2'), 2),
        DepsNode.futureGenerated(AssetId('p1', 'l3'), 3),
      ]);
      final nodeLoader3 = TestDepsNodeLoader(3, [
        DepsNode.generated(AssetId('p1', 'l1'), 1, {AssetId('p1', 'l2')}),
        DepsNode.generated(AssetId('p1', 'l2'), 2, {AssetId('p1', 'l3')}),
        DepsNode.futureGenerated(AssetId('p1', 'l3'), 3),
      ]);
      final nodeLoader4 = TestDepsNodeLoader(4, [
        DepsNode.generated(AssetId('p1', 'l1'), 1, {AssetId('p1', 'l2')}),
        DepsNode.generated(AssetId('p1', 'l2'), 2, {AssetId('p1', 'l3')}),
        DepsNode.generated(AssetId('p1', 'l3'), 3, {}),
      ]);
      final loader = DepsGraphLoader();
      await loader.load(nodeLoader4, AssetId('p1', 'l1'));

      // Dependencies appear in the phase after they are generated.
      expect(await loader.transitiveDepsOf(nodeLoader1, AssetId('p1', 'l1')), {
        AssetId('p1', 'l1'),
      });
      expect(await loader.transitiveDepsOf(nodeLoader2, AssetId('p1', 'l1')), {
        AssetId('p1', 'l1'),
      });
      expect(await loader.transitiveDepsOf(nodeLoader3, AssetId('p1', 'l1')), {
        AssetId('p1', 'l1'),
        AssetId('p1', 'l2'),
      });
      expect(await loader.transitiveDepsOf(nodeLoader4, AssetId('p1', 'l1')), {
        AssetId('p1', 'l1'),
        AssetId('p1', 'l2'),
        AssetId('p1', 'l3'),
      });
    });
  });
}

class TestDepsNodeLoader implements DepsNodeLoader {
  @override
  final int phase;
  final Map<AssetId, DepsNode> results;

  TestDepsNodeLoader(this.phase, Iterable<DepsNode> results)
    : results = {for (final result in results) result.id: result};

  @override
  Future<DepsNode> load(AssetId id) async {
    var result = results[id]!;
    if (result.phase != null && result.phase! >= phase) {
      result = result.rebuild((b) => b..deps = null);
    }
    return result;
  }
}
