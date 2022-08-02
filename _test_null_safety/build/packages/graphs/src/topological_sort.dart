// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:collection/collection.dart';

import 'cycle_exception.dart';

/// Returns a topological sort of the nodes of the directed edges of a graph
/// provided by [nodes] and [edges].
///
/// Each element of the returned iterable is guaranteed to appear after all
/// nodes that have edges leading to that node. The result is not guaranteed to
/// be unique, nor is it guaranteed to be stable across releases of this
/// package; however, it will be stable for a given input within a given package
/// version.
///
/// If [equals] is provided, it is used to compare nodes in the graph. If
/// [equals] is omitted, the node's own [Object.==] is used instead.
///
/// Similarly, if [hashCode] is provided, it is used to produce a hash value
/// for nodes to efficiently calculate the return value. If it is omitted, the
/// key's own [Object.hashCode] is used.
///
/// If you supply one of [equals] or [hashCode], you should generally also to
/// supply the other.
///
/// Throws a [CycleException<T>] if the graph is cyclical.
List<T> topologicalSort<T>(Iterable<T> nodes, Iterable<T> Function(T) edges,
    {bool Function(T, T)? equals, int Function(T)? hashCode}) {
  // https://en.wikipedia.org/wiki/Topological_sorting#Depth-first_search
  var result = QueueList<T>();
  var permanentMark = HashSet<T>(equals: equals, hashCode: hashCode);
  var temporaryMark = LinkedHashSet<T>(equals: equals, hashCode: hashCode);
  void visit(T node) {
    if (permanentMark.contains(node)) return;
    if (temporaryMark.contains(node)) {
      throw CycleException(temporaryMark);
    }

    temporaryMark.add(node);
    for (var child in edges(node)) {
      visit(child);
    }
    temporaryMark.remove(node);
    permanentMark.add(node);
    result.addFirst(node);
  }

  for (var node in nodes) {
    visit(node);
  }
  return result;
}
