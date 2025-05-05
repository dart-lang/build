// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

import '../asset/id.dart';
import 'library_cycle.dart';

part 'library_cycle_graph.g.dart';

/// A directed acyclic graph of [LibraryCycle]s.
abstract class LibraryCycleGraph
    implements Built<LibraryCycleGraph, LibraryCycleGraphBuilder> {
  static Serializer<LibraryCycleGraph> get serializer =>
      _$libraryCycleGraphSerializer;
  LibraryCycle get root;
  BuiltList<LibraryCycleGraph> get children;

  factory LibraryCycleGraph([void Function(LibraryCycleGraphBuilder) updates]) =
      _$LibraryCycleGraph;
  LibraryCycleGraph._();

  /// All subgraphs in the graph, including the root.
  Iterable<LibraryCycleGraph> transitiveGraphs() {
    final result = Set<LibraryCycleGraph>.identity();
    final nextGraphs = [this];

    while (nextGraphs.isNotEmpty) {
      final graph = nextGraphs.removeLast();
      if (result.add(graph)) {
        nextGraphs.addAll(graph.children);
      }
    }

    return result;
  }

  /// All assets in the graph, including the root.
  // TODO(davidmorgan): for best performance the graph should usually stay as a
  // graph rather than being expanded into an explicit set of nodes. So, remove
  // uses of this. If in the end it's still needed, investigate if it needs to
  // be optimized.
  Iterable<AssetId> transitiveDeps() sync* {
    for (final graph in transitiveGraphs()) {
      yield* graph.root.ids;
    }
  }
}
