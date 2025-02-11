// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

/// Finds and returns every node in a graph who's nodes and edges are
/// asynchronously resolved.
///
/// Cycles are allowed. If this is an undirected graph the [edges] function
/// may be symmetric. In this case the [roots] may be any node in each connected
/// graph.
///
/// [V] is the type of values in the graph nodes. [K] must be a type suitable
/// for using as a Map or Set key. [edges] should return the next reachable
/// nodes.
///
/// There are no ordering guarantees. This is useful for ensuring some work is
/// performed at every node in an asynchronous graph, but does not give
/// guarantees that the work is done in topological order.
///
/// If either [readNode] or [edges] throws the error will be forwarded
/// through the result stream and no further nodes will be crawled, though some
/// work may have already been started.
///
/// Crawling is eager, so calls to [edges] may overlap with other calls that
/// have not completed. If the [edges] callback needs to be limited or throttled
/// that must be done by wrapping it before calling [crawlAsync].
///
/// This is a fork of the `package:graph` algorithm changed from recursive to
/// iterative; it is mostly for benchmarking, as `AnalysisDriverModel` will
/// replace the use of this method entirely.
Stream<V> crawlAsync<K extends Object, V>(
  Iterable<K> roots,
  FutureOr<V> Function(K) readNode,
  FutureOr<Iterable<K>> Function(K, V) edges,
) {
  final crawl = _CrawlAsync(roots, readNode, edges)..run();
  return crawl.result.stream;
}

class _CrawlAsync<K, V> {
  final result = StreamController<V>();

  final FutureOr<V> Function(K) readNode;
  final FutureOr<Iterable<K>> Function(K, V) edges;
  final Iterable<K> roots;

  final _seen = HashSet<K>();
  var _next = <K>[];

  _CrawlAsync(this.roots, this.readNode, this.edges);

  /// Add all nodes in the graph to [result] and return a Future which fires
  /// after all nodes have been seen.
  Future<void> run() async {
    try {
      _next.addAll(roots);
      while (_next.isNotEmpty) {
        // Take everything from `_next`, await crawling it in parallel.
        final next = _next;
        _next = <K>[];
        await Future.wait(next.map(_crawlNext), eagerError: true);
      }
      await result.close();
    } catch (e, st) {
      result.addError(e, st);
      await result.close();
    }
  }

  /// Process [key], queue up any of its its edges that haven't been seen.
  Future<void> _crawlNext(K key) async {
    final value = await readNode(key);
    if (result.isClosed) return;
    result.add(value);
    for (final edge in await edges(key, value)) {
      if (_seen.add(edge)) _next.add(edge);
    }
  }
}
