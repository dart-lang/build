// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

import '../asset/id.dart';
import 'library_cycle_graph.dart';
import 'phased_value.dart';

part 'phased_library_cycle_graphs.g.dart';

abstract class PhasedLibraryCycleGraphs
    implements
        Built<PhasedLibraryCycleGraphs, PhasedLibraryCycleGraphsBuilder> {
  static Serializer<PhasedLibraryCycleGraphs> get serializer =>
      _$phasedLibraryCycleGraphsSerializer;

  BuiltMap<AssetId, PhasedValue<LibraryCycleGraph>> get graphs;

  factory PhasedLibraryCycleGraphs([
    void Function(PhasedLibraryCycleGraphsBuilder) b,
  ]) = _$PhasedLibraryCycleGraphs;
  PhasedLibraryCycleGraphs._();

  factory PhasedLibraryCycleGraphs.of(
    Map<AssetId, PhasedValue<LibraryCycleGraph>> graphs,
  ) => _$PhasedLibraryCycleGraphs._(graphs: graphs.build());

  @memoized
  PhasedLibraryCycleGraphs get reversed {
    final reversedGraphs =
        Map<LibraryCycleGraph, LibraryCycleGraphBuilder>.identity();

    for (final phasedGraph in graphs.values) {
      for (final expiringGraph in phasedGraph.values) {
        final graph = expiringGraph.value;
        reversedGraphs.putIfAbsent(
          graph,
          () => LibraryCycleGraphBuilder()..root.replace(graph.root),
        );
        for (final child in graph.children) {
          // TODO(davidmorgan): fix lookup.
          final childGraph = graphs[child]!.values.first.value;
          final builder = reversedGraphs.putIfAbsent(
            childGraph,
            () => LibraryCycleGraphBuilder()..root.replace(childGraph.root),
          );
          builder.children.add(graph.root.ids.first);
        }
      }
    }

    final result = PhasedLibraryCycleGraphsBuilder();
    for (final graphBuilder in reversedGraphs.values) {
      final graph = graphBuilder.build();
      result.graphs[graph.root.ids.first] = PhasedValue.fixed(graph);
    }
    return result.build();
  }
}
