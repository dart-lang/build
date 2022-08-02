// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// An exception indicating that a cycle was detected in a graph that was
/// expected to be acyclic.
class CycleException<T> implements Exception {
  /// The list of nodes comprising the cycle.
  ///
  /// Each node in this list has an edge to the next node. The final node has an
  /// edge to the first node.
  final List<T> cycle;

  CycleException(Iterable<T> cycle) : cycle = List.unmodifiable(cycle);

  @override
  String toString() => 'A cycle was detected in a graph that must be acyclic:\n'
      '${cycle.map((node) => '* $node').join('\n')}';
}
