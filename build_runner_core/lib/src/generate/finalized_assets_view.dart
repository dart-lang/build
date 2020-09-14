// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:path/path.dart' as p;

import '../asset_graph/graph.dart';
import '../asset_graph/node.dart';
import '../asset_graph/optional_output_tracker.dart';

/// A lazily computed view of all the assets available after a build.
///
/// Note that this class has a limited lifetime during which it is available,
/// and should not be used outside of the scope in which it is given. It will
/// throw a [StateError] if you attempt to use it once it has expired.
class FinalizedAssetsView {
  final AssetGraph _assetGraph;
  final OptionalOutputTracker _optionalOutputTracker;

  bool _expired = false;

  FinalizedAssetsView(this._assetGraph, this._optionalOutputTracker);

  List<AssetId> allAssets({String rootDir}) {
    if (_expired) {
      throw StateError(
          'Cannot use a FinalizedAssetsView after it has expired!');
    }
    return _assetGraph.allNodes
        .map((node) {
          if (_shouldSkipNode(node, rootDir, _optionalOutputTracker)) {
            return null;
          }
          return node.id;
        })
        .where((id) => id != null)
        .toList();
  }

  void markExpired() {
    assert(!_expired);
    _expired = true;
  }
}

bool _shouldSkipNode(AssetNode node, String rootDir,
    OptionalOutputTracker optionalOutputTracker) {
  if (!node.isReadable) return true;
  if (node.isDeleted) return true;
  if (rootDir != null &&
      !node.id.path.startsWith('lib/') &&
      !p.isWithin(rootDir, node.id.path)) {
    return true;
  }
  if (node is InternalAssetNode) return true;
  if (node is GeneratedAssetNode) {
    if (!node.wasOutput || node.isFailure || node.state != NodeState.upToDate) {
      return true;
    }
    return !optionalOutputTracker.isRequired(node.id);
  }
  if (node.id.path == '.packages') return true;
  if (node.id.path == '.dart_tool/package_config.json') return true;
  return false;
}
