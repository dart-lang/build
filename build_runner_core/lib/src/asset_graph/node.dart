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

  /// Additional node configuration that's available before the build runs.
  ///
  /// [NodeType.generated], [NodeType.glob] and [NodeType.postProcessAnchor]
  /// have additional configuration.
  final AdditionalNodeConfiguration? configuration;

  /// Additional node state that changes during the build.
  ///
  /// [NodeType.generated], [NodeType.glob] and [NodeType.postProcessAnchor]
  /// have additional state.
  final AdditionalNodeState? state;

  /// The assets that any [Builder] in the build graph declares it may output
  /// when run on this asset.
  final Set<AssetId> _primaryOutputs;
  Iterable<AssetId> get primaryOutputs => _primaryOutputs;

  /// The [AssetId]s of all generated assets which are output by a [Builder]
  /// which reads this asset.
  final Set<AssetId> _outputs;
  Iterable<AssetId> get outputs => _outputs;

  /// The [AssetId]s of all [AssetNode.postProcessAnchor] assets for which this
  /// node is the primary input.
  final Set<AssetId> _anchorOutputs;
  Iterable<AssetId> get anchorOutputs => _anchorOutputs;

  /// The IDs of the [AssetNode.postProcessAnchor] for post process builder
  /// which requested to delete this asset.
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
      type == NodeType.internal || type == NodeType.glob || outputs.isNotEmpty;

  /// An internal asset.
  ///
  /// Examples: `build_runner` generated entrypoint, package config.
  ///
  /// They are "inputs" to the entire build, so they are never explicitly
  /// tracked as inputs.
  AssetNode.internal(this.id, {Digest? lastKnownDigest})
    : type = NodeType.internal,
      configuration = null,
      state = null,
      _primaryOutputs = {},
      _outputs = {},
      _anchorOutputs = {},
      _deletedBy = {};

  /// A manually-written source file.
  AssetNode.source(
    this.id, {
    Digest? lastKnownDigest,
    Iterable<AssetId>? outputs,
    Iterable<AssetId>? primaryOutputs,
  }) : type = NodeType.source,
       configuration = null,
       state = null,
       _primaryOutputs = primaryOutputs?.toSet() ?? {},
       _outputs = outputs?.toSet() ?? {},
       _anchorOutputs = {},
       _deletedBy = {};

  /// A [BuilderOptions] object.
  ///
  /// Each [AssetNode.generated] has one describing its configuration, so it
  /// rebuilds when the configuration changes.
  AssetNode.builderOptions(this.id, {Digest? lastKnownDigest})
    : type = NodeType.builderOptions,
      configuration = null,
      state = null,
      _primaryOutputs = {},
      _outputs = {},
      _anchorOutputs = {},
      _deletedBy = {};

  /// A missing source file.
  ///
  /// Created when a builder tries to read a non-existent file.
  ///
  /// If later the file does exist, the builder must be rerun as it can
  /// produce different output.
  AssetNode.missingSource(this.id, {Digest? lastKnownDigest})
    : type = NodeType.syntheticSource,
      configuration = null,
      state = null,
      _primaryOutputs = {},
      _outputs = {},
      _anchorOutputs = {},
      _deletedBy = {};

  /// Placeholders for useful parts of packages.
  ///
  /// Four types of placeholder are used per package: the `lib` folder, the
  /// `test` folder, the `web` folder, and the whole package.
  ///
  /// TODO(davidmorgan): describe how these are used.
  AssetNode.placeholder(this.id, {Digest? lastKnownDigest})
    : type = NodeType.placeholder,
      configuration = null,
      state = null,
      _primaryOutputs = {},
      _outputs = {},
      _anchorOutputs = {},
      _deletedBy = {};

  /// A generated node.
  AssetNode.generated(
    this.id, {
    Digest? lastKnownDigest,
    required AssetId primaryInput,
    required AssetId builderOptionsId,
    required int phaseNumber,
    required bool isHidden,
    Iterable<AssetId>? inputs,
    Digest? previousInputsDigest,
    required PendingBuildAction state,
    required bool wasOutput,
    required bool isFailure,
  }) : type = NodeType.generated,
       configuration = GeneratedNodeConfiguration(
         primaryInput: primaryInput,
         builderOptionsId: builderOptionsId,
         phaseNumber: phaseNumber,
         isHidden: isHidden,
       ),
       state = GeneratedNodeState(
         inputs: inputs == null ? HashSet() : HashSet.of(inputs),
         previousInputsDigest: previousInputsDigest,
         pendingBuildAction: state,
         wasOutput: wasOutput,
         isFailure: isFailure,
       ),
       _primaryOutputs = {},
       _outputs = {},
       _anchorOutputs = {},
       _deletedBy = {};

  /// A glob node.
  AssetNode.glob(
    this.id, {
    Digest? lastKnownDigest,
    required Glob glob,
    required int phaseNumber,
    Iterable<AssetId>? inputs,
    required PendingBuildAction pendingBuildAction,
    List<AssetId>? results,
  }) : type = NodeType.glob,
       configuration = GlobNodeConfiguration(
         glob: glob,
         phaseNumber: phaseNumber,
       ),
       state = GlobNodeState(
         inputs: HashSet(),
         pendingBuildAction: pendingBuildAction,
         results: results,
       ),
       _primaryOutputs = {},
       _outputs = {},
       _anchorOutputs = {},
       _deletedBy = {};

  static AssetId createGlobNodeId(String package, Glob glob, int phaseNum) =>
      AssetId(
        package,
        'glob.$phaseNum.${base64.encode(utf8.encode(glob.pattern))}',
      );

  /// A [primaryInput] to a [PostBuildAction].
  ///
  /// The [outputs] of this node are the individual outputs created for the
  /// [primaryInput] during the [PostBuildAction] at index [actionNumber].
  AssetNode.postProcessAnchor(
    this.id, {
    required AssetId primaryInput,
    required int actionNumber,
    required AssetId builderOptionsId,
    Digest? previousInputsDigest,
  }) : type = NodeType.postProcessAnchor,
       configuration = PostProcessAnchorNodeConfiguration(
         actionNumber: actionNumber,
         builderOptionsId: builderOptionsId,
         primaryInput: primaryInput,
       ),
       state = PostProcessAnchorNodeState(
         previousInputsDigest: previousInputsDigest,
       ),
       _primaryOutputs = {},
       _outputs = {},
       _anchorOutputs = {},
       _deletedBy = {};

  AssetNode.postProcessAnchorForInputAndAction(
    AssetId primaryInput,
    int actionNumber,
    AssetId builderOptionsId,
  ) : this.postProcessAnchor(
        primaryInput.addExtension('.post_anchor.$actionNumber'),
        primaryInput: primaryInput,
        actionNumber: actionNumber,
        builderOptionsId: builderOptionsId,
      );

  @override
  String toString() => 'AssetNode: $id';

  /// Write access to collections in the node.
  AssetNodeMutator get mutate => AssetNodeMutator(this);

  /// Access to unmodifable views on collections in the node.
  AssetNodeInspector get inspect => AssetNodeInspector(this);

  GeneratedNodeConfiguration get generatedNodeConfiguration =>
      configuration as GeneratedNodeConfiguration;
  GeneratedNodeState get generatedNodeState => state as GeneratedNodeState;

  GlobNodeConfiguration get globNodeConfiguration =>
      configuration as GlobNodeConfiguration;
  GlobNodeState get globNodeState => state as GlobNodeState;

  PostProcessAnchorNodeConfiguration get postProcessAnchorNodeConfiguration =>
      configuration as PostProcessAnchorNodeConfiguration;
  PostProcessAnchorNodeState get postProcessAnchorNodeState =>
      state as PostProcessAnchorNodeState;
}

/// Additional immutable configuration for some node types.
abstract interface class AdditionalNodeConfiguration {}

/// Additional mutable state for some node types.
abstract interface class AdditionalNodeState {}

/// Additional configuration for an [AssetNode.generated].
class GeneratedNodeConfiguration implements AdditionalNodeConfiguration {
  /// The primary input which generated this node.
  final AssetId primaryInput;

  /// The [AssetId] of the node representing the [BuilderOptions] used to create
  /// this node.
  final AssetId builderOptionsId;

  /// The phase in which this node is generated.
  ///
  /// The generator that produces this node can only read files from earlier
  /// phases plus any files it writes itself.
  ///
  /// Other generators and globs can only read this node if they run in a
  /// later phase.
  final int phaseNumber;

  /// Whether the asset should be placed in the build cache.
  final bool isHidden;

  GeneratedNodeConfiguration({
    required this.primaryInput,
    required this.builderOptionsId,
    required this.phaseNumber,
    required this.isHidden,
  });
}

/// State for an [AssetNode.generated] that changes during the build.
class GeneratedNodeState implements AdditionalNodeState {
  /// All the inputs that were read when generating this asset, or deciding not
  /// to generate it.
  final HashSet<AssetId> inputs;

  /// The next work that needs doing on this node.
  PendingBuildAction pendingBuildAction;

  /// Whether the asset was actually output.
  bool wasOutput;

  /// Whether the action which did or would produce this node failed.
  bool isFailure;

  /// A digest combining all digests of all previous inputs.
  ///
  /// Used to determine whether all the inputs to a build step are identical to
  /// the previous run, indicating that the previous output is still valid.
  Digest? previousInputsDigest;

  bool get isSuccessfulFreshOutput =>
      wasOutput && !isFailure && pendingBuildAction == PendingBuildAction.none;

  GeneratedNodeState({
    required this.inputs,
    required this.pendingBuildAction,
    required this.wasOutput,
    required this.isFailure,
    required this.previousInputsDigest,
  });
}

/// Additional configuration for an [AssetNode.glob].
class GlobNodeConfiguration implements AdditionalNodeConfiguration {
  final Glob glob;
  final int phaseNumber;

  GlobNodeConfiguration({required this.glob, required this.phaseNumber});
}

/// State for an [AssetNode.glob] that changes during the build.
class GlobNodeState implements AdditionalNodeState {
  /// All the potential inputs matching this glob.
  ///
  /// This field differs from [results] in that [AssetNode.generated] which may
  /// have been readable but were not output are included here and not in
  /// [results].
  HashSet<AssetId> inputs;

  PendingBuildAction pendingBuildAction;

  /// The actual results of the glob.
  List<AssetId>? results;

  GlobNodeState({
    required this.inputs,
    required this.pendingBuildAction,
    required this.results,
  });
}

// Additional configuration for an [AssetNode.postProcessAnchor].
class PostProcessAnchorNodeConfiguration
    implements AdditionalNodeConfiguration {
  final int actionNumber;
  final AssetId builderOptionsId;
  final AssetId primaryInput;

  PostProcessAnchorNodeConfiguration({
    required this.actionNumber,
    required this.builderOptionsId,
    required this.primaryInput,
  });
}

/// State for an [AssetNode.postProcessAnchor].
class PostProcessAnchorNodeState implements AdditionalNodeState {
  Digest? previousInputsDigest;

  PostProcessAnchorNodeState({this.previousInputsDigest});
}

/// Write access to collections in the node.
///
/// This allows the same access as if they were directly exposed, but makes it
/// easy to search the code for mutates.
extension type AssetNodeMutator(AssetNode node) {
  Set<AssetId> get primaryOutputs => node._primaryOutputs;
  Set<AssetId> get outputs => node._outputs;
  Set<AssetId> get anchorOutputs => node._anchorOutputs;

  Set<AssetId> get deletedBy => node._deletedBy;
}

/// Access to unmodifable views on collections in the node.
extension type AssetNodeInspector(AssetNode node) {
  Set<AssetId> get primaryOutputs => UnmodifiableSetView(node._primaryOutputs);
  Set<AssetId> get outputs => UnmodifiableSetView(node._outputs);
}

/// Work that needs doing for a node that tracks its inputs.
enum PendingBuildAction { none, buildIfInputsChanged, build }
