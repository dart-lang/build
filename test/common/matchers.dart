// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:test/test.dart';

import 'package:build/build.dart';
import 'package:build/src/asset_graph/exceptions.dart';
import 'package:build/src/asset_graph/graph.dart';
import 'package:build/src/asset_graph/node.dart';

final assetGraphVersionException =
    new isInstanceOf<AssetGraphVersionException>();
final assetNotFoundException = new isInstanceOf<AssetNotFoundException>();
final duplicateAssetNodeException =
    new isInstanceOf<DuplicateAssetNodeException>();
final invalidInputException = new isInstanceOf<InvalidInputException>();
final invalidOutputException = new isInstanceOf<InvalidOutputException>();
final packageNotFoundException = new isInstanceOf<PackageNotFoundException>();

equalsAsset(Asset expected) => new _AssetMatcher(expected);

class _AssetMatcher extends Matcher {
  final Asset _expected;

  const _AssetMatcher(this._expected);

  @override
  bool matches(item, _) =>
      item is Asset &&
      item.id == _expected.id &&
      item.stringContents == _expected.stringContents;

  @override
  Description describe(Description description) =>
      description.addDescriptionOf(_expected);
}

equalsAssetGraph(AssetGraph expected) => new _AssetGraphMatcher(expected);

class _AssetGraphMatcher extends Matcher {
  final AssetGraph _expected;

  const _AssetGraphMatcher(this._expected);

  @override
  bool matches(item, _) {
    if (item is! AssetGraph) return false;
    if (item.allNodes.length != _expected.allNodes.length) return false;
    for (var node in item.allNodes) {
      var expectedNode = _expected.get(node.id);
      if (expectedNode == null || expectedNode.id != node.id) return false;
      if (!unorderedEquals(node.outputs).matches(expectedNode.outputs, null)) {
        return false;
      }
      if (item is GeneratedAssetNode) {
        if (expectedNode is! GeneratedAssetNode) return false;
        if (item.primaryInput != expectedNode.primaryInput) return false;
        if (item.needsUpdate != expectedNode.needsUpdate) return false;
        if (item.wasOutput != expectedNode.wasOutput) return false;
      }
    }
    return true;
  }

  @override
  Description describe(Description description) =>
      description.addDescriptionOf(_expected);
}
