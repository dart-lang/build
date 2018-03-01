// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:build/build.dart';
import 'package:crypto/crypto.dart';
import 'package:glob/glob.dart';
import 'package:meta/meta.dart';

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

  /// Whether or not this node was an output of this build.
  bool get isGenerated => false;

  /// Whether or not this asset type can be read.
  ///
  /// This does not indicate whether or not this specific node actually exists
  /// at this moment in time.
  bool get isReadable => true;

  /// Whether or not this node can be used as a primary input.
  ///
  /// Some nodes are valid primary inputs but are not readable (see
  /// [PlaceHolderAssetNode]), while others are readable but are not valid
  /// primary inputs (see [InternalAssetNode]).
  bool get isValidInput => true;

  /// Whether or not changes to this node will have any effect on other nodes.
  ///
  /// Be default, if we haven't computed a digest for this asset and it has no
  /// outputs, then it isn't interesting.
  ///
  /// Checking for a digest alone isn't enough because a file may be deleted
  /// and re-added, in which case it won't have a digest.
  bool get isInteresting => outputs.isNotEmpty || lastKnownDigest != null;

  AssetNode(this.id, {this.lastKnownDigest});

  /// Work around issue where you can't mixin classes into a class with optional
  /// constructor args.
  AssetNode._forMixins(this.id);

  /// Work around issue where you can't mixin classes into a class with optional
  /// constructor args, this one includes the digest.
  AssetNode._forMixinsWithDigest(this.id, this.lastKnownDigest);

  @override
  String toString() => 'AssetNode: $id';
}

/// A node representing some internal asset.
///
/// These nodes are not used as primary inputs, but they are tracked in the
/// asset graph and are readable.
class InternalAssetNode extends AssetNode {
  // These don't have [outputs] but they are interesting regardless.
  @override
  bool get isInteresting => true;

  @override
  bool get isValidInput => false;

  InternalAssetNode(AssetId id, {Digest lastKnownDigest})
      : super(id, lastKnownDigest: lastKnownDigest);

  @override
  String toString() => 'InternalAssetNode: $id';
}

/// A node which is an original source asset (not generated).
class SourceAssetNode extends AssetNode {
  SourceAssetNode(AssetId id, {Digest lastKnownDigest})
      : super(id, lastKnownDigest: lastKnownDigest);

  @override
  String toString() => 'SourceAssetNode: $id';
}

/// States for generated asset nodes.
enum GeneratedNodeState {
  // This node does not need an update, and no checks need to be performed.
  upToDate,
  // This node may need an update, the inputs hash should be checked for
  // changes.
  mayNeedUpdate,
  // This node definitely needs an update, the inputs hash check can be skipped.
  definitelyNeedsUpdate,
}

/// A generated node in the asset graph.
class GeneratedAssetNode extends AssetNode {
  @override
  bool get isGenerated => true;

  /// The phase which generated this asset.
  final int phaseNumber;

  /// The primary input which generated this node.
  final AssetId primaryInput;

  GeneratedNodeState state;

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

  /// The [AssetId] of the node representing the [BuilderOptions] used to create
  /// this node.
  final AssetId builderOptionsId;

  /// Whether the asset should be placed in the build cache.
  final bool isHidden;

  GeneratedAssetNode(
    AssetId id, {
    Digest lastKnownDigest,
    Set<Glob> globs,
    Iterable<AssetId> inputs,
    this.previousInputsDigest,
    @required this.isHidden,
    @required this.state,
    @required this.phaseNumber,
    @required this.wasOutput,
    @required this.primaryInput,
    @required this.builderOptionsId,
  })  : this.globs = globs ?? new Set<Glob>(),
        this.inputs = inputs != null
            ? new SplayTreeSet.from(inputs)
            : new SplayTreeSet<AssetId>(),
        super(id, lastKnownDigest: lastKnownDigest);

  @override
  String toString() =>
      'GeneratedAssetNode: $id generated from input $primaryInput.';
}

/// A node which is not a generated or source asset.
///
/// These are typically not readable or valid as inputs.
abstract class SyntheticAssetNode implements AssetNode {
  @override
  bool get isReadable => false;

  @override
  bool get isValidInput => false;
}

/// A [SyntheticAssetNode] representing a non-existent source.
///
/// Typically these are created as a result of `canRead` calls for assets that
/// don't exist in the graph. We still need to set up proper dependencies so
/// that if that asset gets added later the outputs are properly invalidated.
class SyntheticSourceAssetNode extends AssetNode with SyntheticAssetNode {
  SyntheticSourceAssetNode(AssetId id) : super._forMixins(id);
}

/// A [SyntheticAssetNode] which represents an individual [BuilderOptions]
/// object.
///
/// These are used to track the state of a [BuilderOptions] object, and all
/// [GeneratedAssetNode]s should depend on one of these nodes, which represents
/// their configuration.
class BuilderOptionsAssetNode extends AssetNode with SyntheticAssetNode {
  BuilderOptionsAssetNode(AssetId id, Digest lastKnownDigest)
      : super._forMixinsWithDigest(id, lastKnownDigest);

  @override
  String toString() => 'BuildOptionsAssetNode: $id';
}

/// Placeholder assets are magic files that are usable as inputs but are not
/// readable.
class PlaceHolderAssetNode extends AssetNode with SyntheticAssetNode {
  @override
  bool get isValidInput => true;

  PlaceHolderAssetNode(AssetId id) : super._forMixins(id);

  @override
  String toString() => 'PlaceHolderAssetNode: $id';
}
