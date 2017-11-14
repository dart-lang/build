// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:math' show min;

/// Finds the strongly connected components of an ordered graph using Tarjan's
/// algorithm.
///
/// [V] is the type of values in the graph vertices. [K] must be a type suitable
/// for using as a Map or Set key, and [key] must provide a consistent key for
/// ever vertex. [successors] should return the children for a given vertex.
///
/// [nodes] must contain at least a root of every tree in the graph if there are
/// disjoint subgraphs but it may contain all nodes.
List<List<V>> stronglyConnectedComponents<K, V>(
    Iterable<V> nodes, K Function(V) key, Iterable<V> Function(V) successors) {
  final result = <List<V>>[];
  final lowLinks = <K, int>{};
  final indexes = <K, int>{};
  final onStack = new Set<K>();

  var index = 0;
  var toVisit = new Queue<V>();

  void strongConnect(V node) {
    indexes[key(node)] = index;
    lowLinks[key(node)] = index;
    index++;
    toVisit.addLast(node);
    onStack.add(key(node));
    for (final next in successors(node)) {
      if (!indexes.containsKey(key(next))) {
        strongConnect(next);
        lowLinks[key(node)] = min(lowLinks[key(node)], lowLinks[key(next)]);
      } else if (onStack.contains(key(next))) {
        lowLinks[key(node)] = min(lowLinks[key(node)], indexes[key(next)]);
      }
    }
    if (lowLinks[key(node)] == indexes[key(node)]) {
      final component = <V>[];
      V next;
      do {
        next = toVisit.removeLast();
        onStack.remove(key(next));
        component.add(next);
      } while (key(next) != key(node));
      result.add(component);
    }
  }

  for (final node in nodes) {
    if (!indexes.containsKey(key(node))) strongConnect(node);
  }
  return result;
}
