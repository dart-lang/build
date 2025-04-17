// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/src/asset/id.dart';
import 'package:build/src/library_cycle_graph/library_cycle_graph.dart';
import 'package:build/src/library_cycle_graph/phased_library_cycle_graphs.dart';
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

  group('PhasedLibraryCycleGraphs reversed', () {
    test('one node', () {
      final graphs = PhasedLibraryCycleGraphs.of({
        a1: PhasedValue.fixed(LibraryCycleGraph.of([a1])),
      });
      expect(graphs.reversed, graphs);
    });

    test('two nodes', () {
      final graphs = PhasedLibraryCycleGraphs.of({
        a1: PhasedValue.fixed(LibraryCycleGraph.of([a1], children: [a2])),
        a2: PhasedValue.fixed(LibraryCycleGraph.of([a2])),
      });

      final reversedGraphs = PhasedLibraryCycleGraphs.of({
        a1: PhasedValue.fixed(LibraryCycleGraph.of([a1])),
        a2: PhasedValue.fixed(LibraryCycleGraph.of([a2], children: [a1])),
      });

      expect(graphs.reversed, reversedGraphs);
    });

    test('five nodes', () {
      final graphs = PhasedLibraryCycleGraphs.of({
        a1: PhasedValue.fixed(LibraryCycleGraph.of([a1, a2], children: [a4])),
        a3: PhasedValue.fixed(LibraryCycleGraph.of([a3], children: [a4, a5])),
        a4: PhasedValue.fixed(LibraryCycleGraph.of([a4], children: [a5])),
        a5: PhasedValue.fixed(LibraryCycleGraph.of([a5])),
      });

      final reversedGraphs = PhasedLibraryCycleGraphs.of({
        a1: PhasedValue.fixed(LibraryCycleGraph.of([a1, a2])),
        a3: PhasedValue.fixed(LibraryCycleGraph.of([a3])),
        a4: PhasedValue.fixed(LibraryCycleGraph.of([a4], children: [a1, a3])),
        a5: PhasedValue.fixed(LibraryCycleGraph.of([a5], children: [a3, a4])),
      });

      expect(graphs.reversed, reversedGraphs);
    });
  });
}
