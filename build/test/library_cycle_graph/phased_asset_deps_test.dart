// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/src/asset/id.dart';
import 'package:build/src/library_cycle_graph/asset_deps.dart';
import 'package:build/src/library_cycle_graph/phased_asset_deps.dart';
import 'package:build/src/library_cycle_graph/phased_value.dart';
import 'package:test/test.dart';

void main() {
  final a1 = AssetId('a', '1');
  final a2 = AssetId('a', '2');
  final a3 = AssetId('a', '3');
  final a4 = AssetId('a', '4');
  final a5 = AssetId('a', '5');
  final a6 = AssetId('a', '6');
  final a7 = AssetId('a', '7');
  final a8 = AssetId('a', '8');
  final a9 = AssetId('a', '9');

  group('PhasedAssetDeps reversed', () {
    test('one node', () {
      final deps = PhasedAssetDeps.of({a1: PhasedValue.fixed(AssetDeps([]))});
      expect(deps.reversed, deps);
    });

    test('two nodes', () {
      final deps = PhasedAssetDeps.of({
        a1: PhasedValue.fixed(AssetDeps([a2])),
        a2: PhasedValue.fixed(AssetDeps([])),
      });

      final reversedGraphs = PhasedAssetDeps.of({
        a1: PhasedValue.fixed(AssetDeps([])),
        a2: PhasedValue.fixed(AssetDeps([a1])),
      });

      expect(deps.reversed, reversedGraphs);
    });

    test('five nodes', () {
      final graphs = PhasedAssetDeps.of({
        a1: PhasedValue.fixed(AssetDeps([a4])),
        a2: PhasedValue.fixed(AssetDeps([a1])),
        a3: PhasedValue.fixed(AssetDeps([a4, a5])),
        a4: PhasedValue.fixed(AssetDeps([a5])),
        a5: PhasedValue.fixed(AssetDeps([])),
      });

      final reversedGraphs = PhasedAssetDeps.of({
        a1: PhasedValue.fixed(AssetDeps([a2])),
        a2: PhasedValue.fixed(AssetDeps([])),
        a3: PhasedValue.fixed(AssetDeps([])),
        a4: PhasedValue.fixed(AssetDeps([a1, a3])),
        a5: PhasedValue.fixed(AssetDeps([a3, a4])),
      });

      expect(graphs.reversed, reversedGraphs);
    });

    test('five nodes with phases', () {
      final graphs = PhasedAssetDeps.of({
        a1: PhasedValue.generated(
          atPhase: 1,
          before: AssetDeps.empty,
          AssetDeps([a4]),
        ),
        a2: PhasedValue.fixed(AssetDeps([a1])),
        a3: PhasedValue.generated(
          atPhase: 2,
          before: AssetDeps.empty,
          AssetDeps([a4, a5]),
        ),
        a4: PhasedValue.fixed(AssetDeps([a5])),
        a5: PhasedValue.fixed(AssetDeps([])),
      });

      final reversedGraphs = PhasedAssetDeps.of({
        a1: PhasedValue.fixed(AssetDeps([a2])),
        a2: PhasedValue.fixed(AssetDeps([])),
        a3: PhasedValue.fixed(AssetDeps([])),
        // Reverse deps onto a4 are generated in phases 1 and 2, so they appear
        // in phases 2 and 3.
        a4: PhasedValue((b) {
          b.values.addAll([
            ExpiringValue(AssetDeps([]), expiresAfter: 1),
            ExpiringValue(AssetDeps([a1]), expiresAfter: 2),
            ExpiringValue(AssetDeps([a1, a3])),
          ]);
        }),
        // A reverse dep onto a5 is generated in phase 2 -> appears in 3.
        a5: PhasedValue.generated(
          atPhase: 2,
          before: AssetDeps([a4]),
          AssetDeps([a3, a4]),
        ),
      });

      expect(graphs.reversed, reversedGraphs);
    });

    test('nine nodes with phases', () {
      // A graph with 9 nodes generated in phases 1-5.
      //
      // a1 and a2 are generated in phase 1, then a3-a5 in phase 2, a6-7 in
      // phase 3, a8 in phase 4 and a9 in phase 5; in the ASCII art diagram,
      // nodes on the same vertical line are generated in the same phase.
      //
      // Notes:
      //
      //   - a node is readable the phase _after_ it's generated
      //   - a node can be depended on _before_ it's generated or readable
      //   - node a3 has a self edge not shown in the ASCII art diagram.
      //
      // ```
      //          ------------------\
      //         /                   \
      //        v      v---------\    \
      //       a1 --> a3 -------> a6   |
      //               |               |
      //                \-------> a7   |
      //                          |    |
      //       a2 --> a4 <-------/     |
      //      / ^      |               |
      //      | |      v               |
      //      | \---- a5               |
      //      |                        |
      //       \---------------------> a8 <--- a9
      // ```

      final graphs = PhasedAssetDeps.of({
        a1: PhasedValue.generated(
          atPhase: 1,
          before: AssetDeps.empty,
          AssetDeps({a3}),
        ),
        a2: PhasedValue.generated(
          atPhase: 1,
          before: AssetDeps.empty,
          AssetDeps({a4, a8}),
        ),
        a3: PhasedValue.generated(
          atPhase: 2,
          before: AssetDeps.empty,
          AssetDeps({a3, a6, a7}),
        ),
        a4: PhasedValue.generated(
          atPhase: 2,
          before: AssetDeps.empty,
          AssetDeps({a5}),
        ),
        a5: PhasedValue.generated(
          atPhase: 2,
          before: AssetDeps.empty,
          AssetDeps({a2}),
        ),
        a6: PhasedValue.generated(
          atPhase: 3,
          before: AssetDeps.empty,
          AssetDeps({a3}),
        ),
        a7: PhasedValue.generated(
          atPhase: 3,
          before: AssetDeps.empty,
          AssetDeps({a4}),
        ),
        a8: PhasedValue.generated(
          atPhase: 4,
          before: AssetDeps.empty,
          AssetDeps({a1}),
        ),
        a9: PhasedValue.generated(
          atPhase: 5,
          before: AssetDeps.empty,
          AssetDeps({a8}),
        ),
      });

      final reversedGraphs = PhasedAssetDeps.of({
        a1: PhasedValue.generated(
          atPhase: 4,
          before: AssetDeps.empty,
          AssetDeps([a8]),
        ),
        a2: PhasedValue.generated(
          atPhase: 2,
          before: AssetDeps.empty,
          AssetDeps([a5]),
        ),
        a3: PhasedValue(
          (b) => b.values.addAll([
            ExpiringValue(AssetDeps.empty, expiresAfter: 1),
            ExpiringValue(AssetDeps([a1]), expiresAfter: 2),
            ExpiringValue(AssetDeps([a1, a3]), expiresAfter: 3),
            ExpiringValue(AssetDeps([a1, a3, a6])),
          ]),
        ),
        a4: PhasedValue(
          (b) => b.values.addAll([
            ExpiringValue(AssetDeps.empty, expiresAfter: 1),
            ExpiringValue(AssetDeps([a2]), expiresAfter: 3),
            ExpiringValue(AssetDeps([a2, a7])),
          ]),
        ),
        a5: PhasedValue.generated(
          atPhase: 2,
          before: AssetDeps.empty,
          AssetDeps([a4]),
        ),
        a6: PhasedValue.generated(
          atPhase: 2,
          before: AssetDeps.empty,
          AssetDeps([a3]),
        ),
        a7: PhasedValue.generated(
          atPhase: 2,
          before: AssetDeps.empty,
          AssetDeps([a3]),
        ),
        a8: PhasedValue(
          (b) => b.values.addAll([
            ExpiringValue(AssetDeps.empty, expiresAfter: 1),
            ExpiringValue(AssetDeps([a2]), expiresAfter: 5),
            ExpiringValue(AssetDeps([a2, a9])),
          ]),
        ),
        a9: PhasedValue.fixed(AssetDeps.empty),
      });

      expect(graphs.reversed, reversedGraphs);
    });
  });
}
