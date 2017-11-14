// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:build/build.dart';
import 'package:crypto/crypto.dart';
import 'package:glob/glob.dart';

/// A node in the asset graph which may be an input to other assets.
abstract class AssetNode {
  final AssetId id;

  /// The assets that any [Builder] in the build graph declares it may output
  /// when run on this asset.
  final Set<AssetId> primaryOutputs = new Set<AssetId>();

  /// The [AssetId]s of all generated assets which are output by a [Builder]
  /// which reads this asset.
  final Set<AssetId> outputs = new Set<AssetId>();

  /// The [Digest] for this node in its last known state.
  ///
  /// May be `null` if this asset has no outputs, or if it doesn't actually
  /// exist.
  Digest lastKnownDigest;

  AssetNode(this.id, {this.lastKnownDigest});

  @override
  String toString() => 'AssetNode: $id';
}

/// A node which is an original source asset (not generated).
class SourceAssetNode extends AssetNode {
  SourceAssetNode(AssetId id, {Digest lastKnownDigest})
      : super(id, lastKnownDigest: lastKnownDigest);

  @override
  String toString() => 'SourceAssetNode: $id';
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

  /// All the inputs that were read when generating this asset, or deciding not
  /// to generate it.
  ///
  /// This needs to be an ordered set because we compute combined input digests
  /// using this later on.
  final SplayTreeSet<AssetId> inputs;

  /// A digest combining all digests of all previous inputs.
  ///
  /// Used to determine whether all the inputs to a build step are identical to
  /// the previous run, indicating that the previous output is still valid.
  Digest previousInputsDigest;

  GeneratedAssetNode(this.phaseNumber, this.primaryInput, this.needsUpdate,
      this.wasOutput, AssetId id,
      {Digest lastKnownDigest,
      Set<Glob> globs,
      Iterable<AssetId> inputs,
      this.previousInputsDigest})
      : this.globs = globs ?? new Set<Glob>(),
        this.inputs = inputs != null
            ? new SplayTreeSet.from(inputs)
            : new SplayTreeSet<AssetId>(),
        super(id, lastKnownDigest: lastKnownDigest);

  @override
  String toString() =>
      'GeneratedAssetNode: $id generated from input $primaryInput.';
}
