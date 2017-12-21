// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';

import '../asset_graph/graph.dart';
import '../asset_graph/node.dart';
import '../generate/phase.dart';

/// Collects the expected AssetIds created by [action] when given [input] based
/// on the extension configuration.
///
/// If `action.allowDeclaredOutputConflicts` then this filters the regular
/// [expectedOutputs] to not include pre-existing assets using the [graph].
List<AssetId> expectedActualOutputs(
    BuildAction action, AssetId input, AssetGraph graph, int phaseNumber) {
  // The expected outputs, not taking into account pre-existing assets.
  var allExpectedOutputs = expectedOutputs(action.builder, input);

  if (!action.allowDeclaredOutputConflicts) {
    return allExpectedOutputs.toList();
  }

  return allExpectedOutputs.where((outputId) {
    if (!graph.contains(outputId)) return true;

    var node = graph.get(outputId);
    if (node is GeneratedAssetNode && node.phaseNumber == phaseNumber) {
      return true;
    } else if (action.allowDeclaredOutputConflicts) {
      return false;
    } else {
      throw new StateError(
          'Found node $node but expected a GeneratedAssetNode generated in '
          'phase $phaseNumber.');
    }
  }).toList();
}
