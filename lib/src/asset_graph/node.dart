// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import '../asset/id.dart';
import '../builder/builder.dart';

/// A node in the asset graph.
///
/// This class specifically represents normal (ie: non-generated) assets.
class AssetNode {
  /// The asset this node represents.
  final AssetId id;

  /// The [AssetId]s of all generated assets which depend on this node.
  final outputs = new Set<AssetId>();

  AssetNode(this.id);

  @override
  String toString() => 'AssetNode: $id';
}

/// A generated node in the asset graph.
class GeneratedAssetNode extends AssetNode {
  /// The builder which generated this node.
  final Builder builder;

  /// The primary input which generated this node.
  final AssetId primaryInput;

  /// The phase group number which generates this asset.
  final int generatingPhaseGroup;

  /// Whether or not this asset needs to be updated.
  bool needsUpdate;

  GeneratedAssetNode(this.builder, this.primaryInput, this.generatingPhaseGroup,
      this.needsUpdate, AssetId id)
      : super(id);

  @override
  toString() => 'GeneratedAssetNode: $id generated for input $primaryInput to '
      '$builder in phase group $generatingPhaseGroup.';
}
