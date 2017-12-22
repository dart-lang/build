// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';

import '../asset_graph/exceptions.dart';
import '../asset_graph/graph.dart';
import '../asset_graph/node.dart';

/// Returns whether [output] should be output for [phaseNumber] given the
/// information in the [graph].
///
/// Returns `true` if [output] is not in the graph, or is a
/// generated asset with a matching [phaseNumber].
///
/// Returns `false` if [output] is an existing source asset.
///
/// Returns `true` if [output] is a non-generated, non-source asset (typically
/// this would be a synthetic asset node created by a `canRead` call).
///
/// Throws a [DuplicateAssetNodeException] if [output] is a generated asset with
/// a different phase number.
///
/// If [createShadowNode] is true then this will create shadow nodes for any
/// existing source assets using that function, and assign them to the
/// [SourceAssetNode.shadowNode] field, which must be null.
bool shouldOutputForPhase(AssetId output, int phaseNumber, AssetGraph graph,
    {GeneratedAssetNode createShadowNode()}) {
  if (!graph.contains(output)) return true;

  var node = graph.get(output);
  if (!node.isGenerated) {
    if (node is SourceAssetNode) {
      if (createShadowNode != null) {
        assert(node.shadowNode == null,
            '$node already has a shadowNode ${node.shadowNode}, cant assign ${createShadowNode()}');
        node.shadowNode = createShadowNode();
      }
      return false;
    } else {
      return true;
    }
  } else if ((node as GeneratedAssetNode).phaseNumber == phaseNumber) {
    // Only allow declaring conflicting outputs with source nodes, just
    // filter them from the list here.
    return true;
  } else {
    // Throw an exception for duplicate generated nodes.
    throw new DuplicateAssetNodeException(node);
  }
}
