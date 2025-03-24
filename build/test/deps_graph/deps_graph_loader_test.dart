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
        final loader = DepsGraphLoader(
          TestDepsNodeLoader([DepsNode.missingSource(AssetId('p1', 'l1'))]),
        );
        await loader.load(0, AssetId('p1', 'l1'));
        expect(loader.transitiveDepsOf(0, AssetId('p1', 'l1')), {
          AssetId('p1', 'l1'),
        });
      });

      test('single present node', () async {
        final loader = DepsGraphLoader(
          TestDepsNodeLoader([DepsNode.source(AssetId('p1', 'l1'), {})]),
        );
        await loader.load(0, AssetId('p1', 'l1'));
        expect(loader.transitiveDepsOf(0, AssetId('p1', 'l1')), {
          AssetId('p1', 'l1'),
        });
      });

      test('node with one dep', () async {
        final loader = DepsGraphLoader(
          TestDepsNodeLoader([
            DepsNode.source(AssetId('p1', 'l1'), {AssetId('p1', 'l2')}),
            DepsNode.source(AssetId('p1', 'l2'), {}),
          ]),
        );
        await loader.load(0, AssetId('p1', 'l1'));
        expect(loader.transitiveDepsOf(0, AssetId('p1', 'l1')), {
          AssetId('p1', 'l1'),
          AssetId('p1', 'l2'),
        });
      });

      test('seven node tree', () async {
        final loader = DepsGraphLoader(
          TestDepsNodeLoader([
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
          ]),
        );
        await loader.load(0, AssetId('p1', 'l1'));
        expect(loader.transitiveDepsOf(0, AssetId('p1', 'l1')), {
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
        final loader = DepsGraphLoader(
          TestDepsNodeLoader([
            DepsNode.source(AssetId('p1', 'l1'), {
              AssetId('p1', 'l2'),
              AssetId('p1', 'l3'),
            }),
            DepsNode.source(AssetId('p1', 'l2'), {AssetId('p1', 'l4')}),
            DepsNode.source(AssetId('p1', 'l3'), {AssetId('p1', 'l4')}),
            DepsNode.source(AssetId('p1', 'l4'), {}),
          ]),
        );
        await loader.load(0, AssetId('p1', 'l1'));
        expect(loader.transitiveDepsOf(0, AssetId('p1', 'l1')), {
          AssetId('p1', 'l1'),
          AssetId('p1', 'l2'),
          AssetId('p1', 'l3'),
          AssetId('p1', 'l4'),
        });
      });

      test('two node cycle', () async {
        final loader = DepsGraphLoader(
          TestDepsNodeLoader([
            DepsNode.source(AssetId('p1', 'l1'), {AssetId('p1', 'l2')}),
            DepsNode.source(AssetId('p1', 'l2'), {AssetId('p1', 'l1')}),
          ]),
        );
        await loader.load(0, AssetId('p1', 'l1'));
        expect(loader.transitiveDepsOf(0, AssetId('p1', 'l1')), {
          AssetId('p1', 'l1'),
          AssetId('p1', 'l2'),
        });
      });

      test('two node cycle excluding entrypoint', () async {
        final loader = DepsGraphLoader(
          TestDepsNodeLoader([
            DepsNode.source(AssetId('p1', 'l1'), {AssetId('p1', 'l2')}),
            DepsNode.source(AssetId('p1', 'l2'), {AssetId('p1', 'l3')}),
            DepsNode.source(AssetId('p1', 'l3'), {AssetId('p1', 'l2')}),
          ]),
        );
        await loader.load(0, AssetId('p1', 'l1'));
        expect(loader.transitiveDepsOf(0, AssetId('p1', 'l1')), {
          AssetId('p1', 'l1'),
          AssetId('p1', 'l2'),
          AssetId('p1', 'l3'),
        });
      });
    });
  });

  group('with generated nodes', () {
    test('single generated node', () async {
      final loader = DepsGraphLoader(
        TestDepsNodeLoader([DepsNode.generated(AssetId('p1', 'l1'), 1, {})]),
      );
      await loader.load(2, AssetId('p1', 'l1'));

      // It's a dependency irrespective of the phase.
      expect(loader.transitiveDepsOf(0, AssetId('p1', 'l1')), {
        AssetId('p1', 'l1'),
      });
      expect(loader.transitiveDepsOf(2, AssetId('p1', 'l1')), {
        AssetId('p1', 'l1'),
      });
    });

    test('sequence of three nodes', () async {
      final loader = DepsGraphLoader(
        TestDepsNodeLoader([
          DepsNode.generated(AssetId('p1', 'l1'), 1, {AssetId('p1', 'l2')}),
          DepsNode.generated(AssetId('p1', 'l2'), 2, {AssetId('p1', 'l3')}),
          DepsNode.generated(AssetId('p1', 'l3'), 3, {}),
        ]),
      );
      await loader.load(4, AssetId('p1', 'l1'));

      // Dependencies appear in the phase after they are generated.
      expect(loader.transitiveDepsOf(1, AssetId('p1', 'l1')), {
        AssetId('p1', 'l1'),
      });
      expect(loader.transitiveDepsOf(2, AssetId('p1', 'l1')), {
        AssetId('p1', 'l1'),
      });
      expect(loader.transitiveDepsOf(3, AssetId('p1', 'l1')), {
        AssetId('p1', 'l1'),
        AssetId('p1', 'l2'),
      });
      expect(loader.transitiveDepsOf(4, AssetId('p1', 'l1')), {
        AssetId('p1', 'l1'),
        AssetId('p1', 'l2'),
        AssetId('p1', 'l3'),
      });
    });

    test('sequence of three with nodes not generated yet', () async {
      final loader = DepsGraphLoader(
        TestDepsNodeLoader([
          DepsNode.generated(AssetId('p1', 'l1'), 1, {AssetId('p1', 'l2')}),
          DepsNode.generated(AssetId('p1', 'l2'), 2, {AssetId('p1', 'l3')}),
          DepsNode.generated(AssetId('p1', 'l3'), 3, {}),
        ]),
      );
      await loader.load(1, AssetId('p1', 'l1'));

      // Nodes not readable yet as "load" was done at phase 1.
      expect(loader.transitiveDepsOf(1, AssetId('p1', 'l1')), {
        AssetId('p1', 'l1'),
      });
      expect(
        () => loader.transitiveDepsOf(2, AssetId('p1', 'l1')),
        throwsA(isA<StateError>()),
      );
      expect(
        () => loader.transitiveDepsOf(3, AssetId('p1', 'l1')),
        throwsA(isA<StateError>()),
      );
      expect(
        () => loader.transitiveDepsOf(4, AssetId('p1', 'l1')),
        throwsA(isA<StateError>()),
      );

      // Readable if loaded at a late enough phase.
      await loader.load(5, AssetId('p1', 'l1'));
      expect(loader.transitiveDepsOf(3, AssetId('p1', 'l1')), {
        AssetId('p1', 'l1'),
        AssetId('p1', 'l2'),
      });
      expect(loader.transitiveDepsOf(4, AssetId('p1', 'l1')), {
        AssetId('p1', 'l1'),
        AssetId('p1', 'l2'),
        AssetId('p1', 'l3'),
      });
    });
  });
}

class TestDepsNodeLoader implements DepsNodeLoader {
  final Map<AssetId, DepsNode> results;

  TestDepsNodeLoader(Iterable<DepsNode> results)
    : results = {for (final result in results) result.id: result};

  @override
  Future<DepsNode> load(int phase, AssetId id) async {
    var result = results[id]!;
    if (result.phase != null && result.phase! >= phase) {
      result = result.rebuild((b) => b..deps = null);
    }
    return result;
  }
}
