// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';

import '../asset_graph/exceptions.dart';
import '../asset_graph/graph.dart';
import '../asset_graph/node.dart';

/// Returns whether [output] conflicts with an existing asset.
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
/// a different phase number;
bool shouldOutputForPhase(AssetId output, int phaseNumber, AssetGraph graph) {
  if (!graph.contains(output)) return true;

  var node = graph.get(output);
  if (!node.isGenerated) {
    return node is! SourceAssetNode;
  } else if ((node as GeneratedAssetNode).phaseNumber == phaseNumber) {
    // Only allow declaring conflicting outputs with source nodes, just
    // filter them from the list here.
    return true;
  } else {
    // Throw an exception for duplicate generated nodes.
    throw new DuplicateAssetNodeException(node);
  }
}
