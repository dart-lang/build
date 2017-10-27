// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:glob/glob.dart';

/// A node in the asset graph which may be an input to other assets.
class AssetNode {
  final AssetId id;

  /// The assets that any [Builder] in the build graph declares it may output
  /// when run on this asset.
  final Set<AssetId> primaryOutputs = new Set<AssetId>();

  /// The [AssetId]s of all generated assets which are output by a [Builder]
  /// which reads this asset.
  final Set<AssetId> outputs = new Set<AssetId>();

  AssetNode(this.id);

  @override
  String toString() => 'AssetNode: $id';
}

/// A node which is not a generated or source asset.
///
/// Typically these are created as a result of `canRead` calls for assets that
/// don't exist in the graph. We still need to set up proper dependencies so
/// that if that asset gets added later the outputs are properly invalidated.
class SyntheticAssetNode extends AssetNode {
  SyntheticAssetNode(AssetId id) : super(id);

  @override
  String toString() => 'SyntheticAssetNode: $id';
}

/// A generated node in the asset graph.
class GeneratedAssetNode extends AssetNode {
  /// The phase which generated this asset.
  final int phaseNumber;

  /// The primary input which generated this node.
  ///
  /// May be `null` in the case of a `PackageBuilder`.
  final AssetId primaryInput;

  /// Whether or not this asset needs to be updated.
  bool needsUpdate;

  /// Whether the asset was actually output.
  bool wasOutput;

  /// All the [Glob]s that were ran to create this asset.
  ///
  /// Any new or deleted files matching this glob should invalidate this node.
  Set<Glob> globs;

  GeneratedAssetNode(this.phaseNumber, this.primaryInput, this.needsUpdate,
      this.wasOutput, AssetId id,
      {Set<Glob> globs})
      : this.globs = globs ?? new Set<Glob>(),
        super(id);

  @override
  String toString() =>
      'GeneratedAssetNode: $id generated from input $primaryInput.';
}
