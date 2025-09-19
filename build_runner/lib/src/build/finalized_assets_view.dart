// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:path/path.dart' as p;

import '../build_plan/package_graph.dart';
import 'asset_graph/graph.dart';
import 'asset_graph/node.dart';
import 'optional_output_tracker.dart';

/// A lazily computed view of all the assets available after a build.
class FinalizedAssetsView {
  final AssetGraph _assetGraph;
  final PackageGraph _packageGraph;
  final OptionalOutputTracker? _optionalOutputTracker;

  FinalizedAssetsView(
    this._assetGraph,
    this._packageGraph,
    this._optionalOutputTracker,
  );

  List<AssetId> allAssets({String? rootDir}) {
    if (_optionalOutputTracker == null) return [];
    return _assetGraph.allNodes
        .map((node) {
          if (_shouldSkipNode(
            node,
            rootDir,
            _packageGraph,
            _optionalOutputTracker,
          )) {
            return null;
          }
          return node.id;
        })
        .whereType<AssetId>()
        .toList();
  }
}

bool _shouldSkipNode(
  AssetNode node,
  String? rootDir,
  PackageGraph packageGraph,
  OptionalOutputTracker optionalOutputTracker,
) {
  if (!node.isFile) return true;
  if (node.isDeleted) return true;

  // Exclude non-lib assets if they're outside of the root directory or not from
  // root package.
  if (!node.id.path.startsWith('lib/')) {
    if (rootDir != null && !p.isWithin(rootDir, node.id.path)) return true;
    if (node.id.package != packageGraph.root.name) return true;
  }

  if (node.type == NodeType.internal || node.type == NodeType.glob) return true;
  if (node.type == NodeType.generated) {
    if (!node.wasOutput || node.generatedNodeState!.result == false) {
      return true;
    }
    return !optionalOutputTracker.isRequired(node.id);
  }
  if (node.id.path == '.packages') return true;
  if (node.id.path == '.dart_tool/package_config.json') return true;
  return false;
}
