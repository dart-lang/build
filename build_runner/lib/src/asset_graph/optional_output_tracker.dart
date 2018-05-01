// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';

import '../generate/phase.dart';
import 'graph.dart';
import 'node.dart';

class OptionalOutputTracker {
  final _checkedOutputs = <AssetId, bool>{};
  final AssetGraph _assetGraph;
  final List<BuildPhase> _buildPhases;

  OptionalOutputTracker(this._assetGraph, this._buildPhases);

  bool isRequired(AssetId output, [Set<AssetId> currentlyChecking]) {
    currentlyChecking ??= new Set<AssetId>();
    if (currentlyChecking.contains(output)) return false;
    currentlyChecking.add(output);

    final node = _assetGraph.get(output);
    if (node is! GeneratedAssetNode) return true;
    final generatedNode = node as GeneratedAssetNode;
    final phase = _buildPhases[generatedNode.phaseNumber];
    if (!phase.isOptional) return true;
    return _checkedOutputs.putIfAbsent(
        output,
        () =>
            generatedNode.outputs
                .any((o) => isRequired(o, currentlyChecking)) ||
            _assetGraph
                .outputsForPhase(output.package, generatedNode.phaseNumber)
                .map((n) => n.id)
                .any((o) => isRequired(o, currentlyChecking)));
  }
}
