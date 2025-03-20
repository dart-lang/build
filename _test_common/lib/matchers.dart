// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore: implementation_imports
import 'package:build_runner_core/src/asset_graph/exceptions.dart';
// ignore: implementation_imports
import 'package:build_runner_core/src/asset_graph/graph.dart';
// ignore: implementation_imports
import 'package:build_runner_core/src/asset_graph/node.dart';
import 'package:test/test.dart';

final Matcher throwsCorruptedException = throwsA(
  const TypeMatcher<AssetGraphCorruptedException>(),
);
final Matcher duplicateAssetNodeException =
    const TypeMatcher<DuplicateAssetNodeException>();

Matcher equalsAssetGraph(AssetGraph expected) => _AssetGraphMatcher(expected);

class _AssetGraphMatcher extends Matcher {
  final AssetGraph _expected;
  final Matcher _matcher;

  _AssetGraphMatcher(this._expected)
    : _matcher = equals(_graphToList(_expected));

  /// Converts [graph] to a list of [AssetNode], sorted by ID, for comparison.
  static List<AssetNode> _graphToList(AssetGraph graph) =>
      graph.allNodes.toList()
        ..sort((a, b) => a.id.toString().compareTo(b.id.toString()));

  @override
  bool matches(dynamic item, Map<dynamic, dynamic> matchState) {
    if (item is! AssetGraph) return false;
    return _matcher.matches(_graphToList(item), matchState);
  }

  @override
  Description describe(Description description) =>
      description.addDescriptionOf(_expected);

  @override
  Description describeMismatch(
    dynamic item,
    Description mismatchDescription,
    Map matchState,
    bool verbose,
  ) => _matcher.describeMismatch(
    item is AssetGraph ? _graphToList(item) : '(not an AssetGraph!) $item',
    mismatchDescription,
    matchState,
    verbose,
  );
}
