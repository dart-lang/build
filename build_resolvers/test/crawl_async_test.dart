// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build_resolvers/src/crawl_async.dart';
import 'package:test/test.dart';

// This is a fork of the `package:graph` test of the same name, there are
// no changes. TODO(davidmorgan): remove when `crawlAsync` is removed
// in favor of the new `AnalysisDriverModel`.

void main() {
  group('asyncCrawl', () {
    Future<List<String?>> crawl(
      Map<String, List<String>?> g,
      Iterable<String> roots,
    ) {
      final graph = AsyncGraph(g);
      return crawlAsync(roots, graph.readNode, graph.edges).toList();
    }

    test('empty result for empty graph', () async {
      final result = await crawl({}, []);
      expect(result, isEmpty);
    });

    test('single item for a single node', () async {
      final result = await crawl({'a': []}, ['a']);
      expect(result, ['a']);
    });

    test('hits every node in a graph', () async {
      final result = await crawl(
        {
          'a': ['b', 'c'],
          'b': ['c'],
          'c': ['d'],
          'd': [],
        },
        ['a'],
      );
      expect(result, hasLength(4));
      expect(
        result,
        allOf(contains('a'), contains('b'), contains('c'), contains('d')),
      );
    });

    test('handles cycles', () async {
      final result = await crawl(
        {
          'a': ['b'],
          'b': ['c'],
          'c': ['b'],
        },
        ['a'],
      );
      expect(result, hasLength(3));
      expect(result, allOf(contains('a'), contains('b'), contains('c')));
    });

    test('handles self cycles', () async {
      final result = await crawl(
        {
          'a': ['b'],
          'b': ['b'],
        },
        ['a'],
      );
      expect(result, hasLength(2));
      expect(result, allOf(contains('a'), contains('b')));
    });

    test('allows null edges', () async {
      final result = await crawl(
        {
          'a': ['b'],
          'b': null,
        },
        ['a'],
      );
      expect(result, hasLength(2));
      expect(result, allOf(contains('a'), contains('b')));
    });

    test('allows null nodes', () async {
      final result = await crawl(
        {
          'a': ['b'],
        },
        ['a'],
      );
      expect(result, ['a', null]);
    });

    test('surfaces exceptions for crawling edges', () {
      final graph = {
        'a': ['b'],
      };
      final nodes = crawlAsync(
        ['a'],
        (n) => n,
        (k, n) => k == 'b' ? throw ArgumentError() : graph[k] ?? <String>[],
      );
      expect(nodes, emitsThrough(emitsError(isArgumentError)));
    });

    test('surfaces exceptions for resolving keys', () {
      final graph = {
        'a': ['b'],
      };
      final nodes = crawlAsync(
        ['a'],
        (n) => n == 'b' ? throw ArgumentError() : n,
        (k, n) => graph[k] ?? <Never>[],
      );
      expect(nodes, emitsThrough(emitsError(isArgumentError)));
    });
  });
}

/// A representation of a Graph where keys can asynchronously be resolved to
/// real values or to edges.
class AsyncGraph {
  final Map<String, List<String>?> graph;

  AsyncGraph(this.graph);

  Future<String?> readNode(String node) async =>
      graph.containsKey(node) ? node : null;

  Future<Iterable<String>> edges(String key, String? node) async =>
      graph[key] ?? <Never>[];
}
