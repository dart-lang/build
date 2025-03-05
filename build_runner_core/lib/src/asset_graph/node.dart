// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:convert';

import 'package:build/build.dart';
import 'package:crypto/crypto.dart';
import 'package:glob/glob.dart';

import '../generate/phase.dart';

/// Types of [AssetNode].
enum NodeType {
  builderOptions,
  generated,
  glob,
  internal,
  placeholder,
  postProcessAnchor,
  source,
  syntheticSource,
}

/// A node in the asset graph which may be an input to other assets.
class AssetNode {
  final AssetId id;
  final NodeType type;

  /// The assets that any [Builder] in the build graph declares it may output
  /// when run on this asset.
  final Set<AssetId> _primaryOutputs;
  Iterable<AssetId> get primaryOutputs => _primaryOutputs;

  /// The [AssetId]s of all generated assets which are output by a [Builder]
  /// which reads this asset.
  final Set<AssetId> _outputs;
  Iterable<AssetId> get outputs => _outputs;

  /// The [AssetId]s of all [PostProcessAnchorNode] assets for which this node
  /// is the primary input.
  final Set<AssetId> _anchorOutputs;
  Iterable<AssetId> get anchorOutputs => _anchorOutputs;

  /// The [Digest] for this node in its last known state.
  ///
  /// May be `null` if this asset has no outputs, or if it doesn't actually
  /// exist.
  Digest? _lastKnownDigest;
  Digest? get lastKnownDigest => _lastKnownDigest;

  /// The IDs of the [PostProcessAnchorNode] for post process builder which
  /// requested to delete this asset.
  final Set<AssetId> _deletedBy;
  Iterable<AssetId> get deletedBy => _deletedBy;

  /// Whether this asset is a normal, readable file.
  ///
  /// Does not guarantee that the file currently exists.
  bool get isFile =>
      type == NodeType.generated ||
      type == NodeType.source ||
      type == NodeType.internal;

  /// Whether this node is tracked as an input in the asset graph.
  ///
  /// [NodeType.internal] nodes are a dependency of _all_ builders, so they are
  /// inputs but not tracked inputs.
  bool get isTrackedInput =>
      type == NodeType.generated ||
      type == NodeType.source ||
      type == NodeType.placeholder;

  /// Whether the node is deleted.
  ///
  /// Deleted nodes are ignored in the final merge step and watch handlers.
  bool get isDeleted => deletedBy.isNotEmpty;

  /// Whether changes to this node will have any effect on other nodes.
  bool get changesRequireRebuild =>
      type == NodeType.internal ||
      type == NodeType.glob ||
      outputs.isNotEmpty ||
      lastKnownDigest != null;

  AssetNode(this.id, {required this.type, Digest? lastKnownDigest})
    : _primaryOutputs = {},
      _outputs = {},
      _anchorOutputs = {},
      _lastKnownDigest = lastKnownDigest,
      _deletedBy = {};

  /// An internal asset.
  ///
  /// Examples: `build_runner` generated entrypoint, package config.
  ///
  /// They are "inputs" to the entire build, so they are never explicitly
  /// tracked as inputs.
  AssetNode.internal(this.id, {Digest? lastKnownDigest})
    : type = NodeType.internal,
      _primaryOutputs = {},
      _outputs = {},
      _anchorOutputs = {},
      _lastKnownDigest = lastKnownDigest,
      _deletedBy = {};

  /// A manually-written source file.
  AssetNode.source(
    this.id, {
    Digest? lastKnownDigest,
    Iterable<AssetId>? outputs,
    Iterable<AssetId>? primaryOutputs,
  }) : type = NodeType.source,
       _primaryOutputs = primaryOutputs?.toSet() ?? {},
       _outputs = outputs?.toSet() ?? {},
       _anchorOutputs = {},
       _lastKnownDigest = lastKnownDigest,
       _deletedBy = {};

  /// A [BuilderOptions] object.
  ///
  /// Each [GeneratedAssetNode] has one describing its configuration, so it
  /// rebuilds when the configuration changes.
  AssetNode.builderOptions(this.id, {Digest? lastKnownDigest})
    : type = NodeType.builderOptions,
      _primaryOutputs = {},
      _outputs = {},
      _anchorOutputs = {},
      _lastKnownDigest = lastKnownDigest,
      _deletedBy = {};

  /// A missing source file.
  ///
  /// Created when a builder tries to read a non-existent file.
  ///
  /// If later the file does exist, the builder must be rerun as it can
  /// produce different output.
  AssetNode.missingSource(this.id, {Digest? lastKnownDigest})
    : type = NodeType.syntheticSource,
      _primaryOutputs = {},
      _outputs = {},
      _anchorOutputs = {},
      _lastKnownDigest = lastKnownDigest,
      _deletedBy = {};

  /// Placeholders for useful parts of packages.
  ///
  /// Four types of placeholder are used per package: the `lib` folder, the
  /// `test` folder, the `web` folder, and the whole package.
  ///
  /// TODO(davidmorgan): describe how these are used.
  AssetNode.placeholder(this.id, {Digest? lastKnownDigest})
    : type = NodeType.placeholder,
      _primaryOutputs = {},
      _outputs = {},
      _anchorOutputs = {},
      _lastKnownDigest = lastKnownDigest,
      _deletedBy = {};

  @override
  String toString() => 'AssetNode: $id';

  /// Write access to collections in the node.
  AssetNodeMutator get mutate => AssetNodeMutator(this);

  /// Access to unmodifable views on collections in the node.
  AssetNodeInspector get inspect => AssetNodeInspector(this);
}

/// Write access to collections in the node.
extension type AssetNodeMutator(AssetNode node) {
  Set<AssetId> get primaryOutputs => node._primaryOutputs;
  Set<AssetId> get outputs => node._outputs;
  Set<AssetId> get anchorOutputs => node._anchorOutputs;

  Digest? get lastKnownDigest => node._lastKnownDigest;
  set lastKnownDigest(Digest? value) => node._lastKnownDigest = value;

  Set<AssetId> get deletedBy => node._deletedBy;
}

/// Access to unmodifable views on collections in the node.
extension type AssetNodeInspector(AssetNode node) {
  Set<AssetId> get primaryOutputs => UnmodifiableSetView(node._primaryOutputs);
  Set<AssetId> get outputs => UnmodifiableSetView(node._outputs);
}

/// States for nodes that can be invalidated.
enum NodeState {
  // This node does not need an update, and no checks need to be performed.
  upToDate,
  // This node may need an update, the inputs hash should be checked for
  // changes.
  mayNeedUpdate,
  // This node definitely needs an update, the inputs hash check can be skipped.
  definitelyNeedsUpdate,
}

/// A generated node in the asset graph.
class GeneratedAssetNode extends AssetNode implements NodeWithInputs {
  @override
  final int phaseNumber;

  /// The primary input which generated this node.
  final AssetId primaryInput;

  @override
  NodeState state;

  /// Whether the asset was actually output.
  bool wasOutput;

  /// All the inputs that were read when generating this asset, or deciding not
  /// to generate it.
  ///
  /// This needs to be an ordered set because we compute combined input digests
  /// using this later on.
  @override
  HashSet<AssetId> inputs;

  /// A digest combining all digests of all previous inputs.
  ///
  /// Used to determine whether all the inputs to a build step are identical to
  /// the previous run, indicating that the previous output is still valid.
  Digest? previousInputsDigest;

  /// Whether the action which did or would produce this node failed.
  bool isFailure;

  /// The [AssetId] of the node representing the [BuilderOptions] used to create
  /// this node.
  final AssetId builderOptionsId;

  /// Whether the asset should be placed in the build cache.
  final bool isHidden;

  GeneratedAssetNode(
    super.id, {
    super.lastKnownDigest,
    Iterable<AssetId>? inputs,
    this.previousInputsDigest,
    required this.isHidden,
    required this.state,
    required this.phaseNumber,
    required this.wasOutput,
    required this.isFailure,
    required this.primaryInput,
    required this.builderOptionsId,
  }) : inputs = inputs != null ? HashSet.from(inputs) : HashSet(),
       super(type: NodeType.generated);

  @override
  String toString() =>
      'GeneratedAssetNode: $id generated from input $primaryInput.';
}

/// A [primaryInput] to a [PostBuildAction].
///
/// The [outputs] of this node are the individual outputs created for the
/// [primaryInput] during the [PostBuildAction] at index [actionNumber].
class PostProcessAnchorNode extends AssetNode {
  final int actionNumber;
  final AssetId builderOptionsId;
  final AssetId primaryInput;
  Digest? previousInputsDigest;

  PostProcessAnchorNode(
    super.id,
    this.primaryInput,
    this.actionNumber,
    this.builderOptionsId, {
    this.previousInputsDigest,
  }) : super(type: NodeType.postProcessAnchor);

  PostProcessAnchorNode.forInputAndAction(
    AssetId primaryInput,
    int actionNumber,
    AssetId builderOptionsId,
  ) : this(
        primaryInput.addExtension('.post_anchor.$actionNumber'),
        primaryInput,
        actionNumber,
        builderOptionsId,
      );
}

/// A node representing a glob ran from a builder.
///
/// The [id] must always be unique to a given package, phase, and glob
/// pattern.
class GlobAssetNode extends AssetNode implements NodeWithInputs {
  final Glob glob;

  /// All the potential inputs matching this glob.
  ///
  /// This field differs from [results] in that [GeneratedAssetNode] which may
  /// have been readable but were not output are included here and not in
  /// [results].
  @override
  HashSet<AssetId> inputs;

  @override
  final int phaseNumber;

  /// The actual results of the glob.
  List<AssetId>? results;

  @override
  NodeState state;

  GlobAssetNode(
    super.id,
    this.glob,
    this.phaseNumber,
    this.state, {
    HashSet<AssetId>? inputs,
    super.lastKnownDigest,
    this.results,
  }) : inputs = inputs ?? HashSet(),
       super(type: NodeType.glob);

  static AssetId createId(String package, Glob glob, int phaseNum) => AssetId(
    package,
    'glob.$phaseNum.${base64.encode(utf8.encode(glob.pattern))}',
  );
}

/// A node which has [inputs], a [NodeState], and a [phaseNumber].
abstract class NodeWithInputs implements AssetNode {
  HashSet<AssetId> get inputs;

  int get phaseNumber;

  abstract NodeState state;
}
