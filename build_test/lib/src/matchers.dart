// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:test/test.dart';

import 'package:build/build.dart';
import 'package:build_runner/src/asset_graph/exceptions.dart';
import 'package:build_runner/src/asset_graph/graph.dart';
import 'package:build_runner/src/asset_graph/node.dart';

final Matcher assetGraphVersionException =
    new isInstanceOf<AssetGraphVersionException>();
final Matcher assetNotFoundException =
    new isInstanceOf<AssetNotFoundException>();
final Matcher duplicateAssetNodeException =
    new isInstanceOf<DuplicateAssetNodeException>();
final Matcher invalidInputException = new isInstanceOf<InvalidInputException>();
final Matcher invalidOutputException =
    new isInstanceOf<InvalidOutputException>();
final Matcher packageNotFoundException =
    new isInstanceOf<PackageNotFoundException>();

Matcher equalsAsset(Asset expected) => new _AssetMatcher(expected);

class _AssetMatcher extends Matcher {
  final Asset _expected;

  const _AssetMatcher(this._expected);

  @override
  bool matches(Object item, _) =>
      item is Asset &&
      item.id == _expected.id &&
      item.stringContents == _expected.stringContents;

  @override
  Description describe(Description description) =>
      description.addDescriptionOf(_expected);
}

Matcher equalsAssetGraph(AssetGraph expected, {bool checkValidAsOf}) =>
    new _AssetGraphMatcher(expected, checkValidAsOf ?? false);

class _AssetGraphMatcher extends Matcher {
  final AssetGraph _expected;
  final bool _checkValidAsOf;

  const _AssetGraphMatcher(this._expected, this._checkValidAsOf);

  @override
  bool matches(dynamic item, _) {
    if (item is! AssetGraph) return false;
    if (item.allNodes.length != _expected.allNodes.length) return false;
    if (_checkValidAsOf && (item.validAsOf != _expected.validAsOf)) {
      return false;
    }
    for (var node in item.allNodes) {
      var expectedNode = _expected.get(node.id);
      if (expectedNode == null || expectedNode.id != node.id) return false;
      if (!unorderedEquals(node.outputs).matches(expectedNode.outputs, null)) {
        return false;
      }
      if (item is GeneratedAssetNode) {
        if (expectedNode is GeneratedAssetNode) {
          if (item.primaryInput != expectedNode.primaryInput) return false;
          if (item.needsUpdate != expectedNode.needsUpdate) return false;
          if (item.wasOutput != expectedNode.wasOutput) return false;
        } else {
          return false;
        }
      }
    }
    return true;
  }

  @override
  Description describe(Description description) =>
      description.addDescriptionOf(_expected);
}
