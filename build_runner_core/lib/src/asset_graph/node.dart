// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:convert';

import 'package:build/build.dart' hide Builder;
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:crypto/crypto.dart';
import 'package:glob/glob.dart';

import '../generate/phase.dart';

part 'node.g.dart';

/// Types of [AssetNode].
class NodeType extends EnumClass {
  static const NodeType builderOptions = _$builderOptions;
  static const NodeType generated = _$generated;
  static const NodeType glob = _$glob;
  static const NodeType internal = _$internal;
  static const NodeType placeholder = _$placeholder;
  static const NodeType postProcessAnchor = _$postProcessAnchor;
  static const NodeType source = _$source;
  static const NodeType syntheticSource = _$syntheticSource;

  const NodeType._(super.name);

  static BuiltSet<NodeType> get values => _$nodeTypeValues;
  static NodeType valueOf(String name) => _$nodeTypeValueOf(name);
}

/// A node in the asset graph which may be an input to other assets.
abstract class AssetNode implements Built<AssetNode, AssetNodeBuilder> {
  AssetId get id;
  NodeType get type;

  /// Additional node configuration that's available before the build runs.
  ///
  /// [NodeType.generated], [NodeType.glob] and [NodeType.postProcessAnchor]
  /// have additional configuration.
  AdditionalNodeConfiguration? get configuration;

  /// Additional node state that changes during the build.
  ///
  /// [NodeType.generated], [NodeType.glob] and [NodeType.postProcessAnchor]
  /// have additional state.
  AdditionalNodeState? get state;

  /// The assets that any [Builder] in the build graph declares it may output
  /// when run on this asset.
  BuiltSet<AssetId> get primaryOutputs;

  /// The [AssetId]s of all generated assets which are output by a [Builder]
  /// which reads this asset.
  BuiltSet<AssetId> get outputs;

  /// The [AssetId]s of all [AssetNode.postProcessAnchor] assets for which this
  /// node is the primary input.
  BuiltSet<AssetId> get anchorOutputs;

  /// The [Digest] for this node in its last known state.
  ///
  /// May be `null` if this asset has no outputs, or if it doesn't actually
  /// exist.
  Digest? get lastKnownDigest;

  /// The IDs of the [AssetNode.postProcessAnchor] for post process builder
  /// which requested to delete this asset.
  BuiltSet<AssetId> get deletedBy;

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

  factory AssetNode([void Function(AssetNodeBuilder) updates]) = _$AssetNode;

  /// An internal asset.
  ///
  /// Examples: `build_runner` generated entrypoint, package config.
  ///
  /// They are "inputs" to the entire build, so they are never explicitly
  /// tracked as inputs.
  factory AssetNode.internal(AssetId id, {Digest? lastKnownDigest}) =>
      AssetNode(
        (b) =>
            b
              ..id = id
              ..type = NodeType.internal
              ..lastKnownDigest = lastKnownDigest,
      );

  /// A manually-written source file.
  factory AssetNode.source(
    AssetId id, {
    Digest? lastKnownDigest,
    Iterable<AssetId>? outputs,
    Iterable<AssetId>? primaryOutputs,
  }) => AssetNode(
    (b) =>
        b
          ..id = id
          ..type = NodeType.source
          ..primaryOutputs.replace(primaryOutputs ?? {})
          ..outputs.replace(outputs ?? {})
          ..lastKnownDigest = lastKnownDigest,
  );

  /// A [BuilderOptions] object.
  ///
  /// Each [AssetNode.generated] has one describing its configuration, so it
  /// rebuilds when the configuration changes.
  factory AssetNode.builderOptions(AssetId id, {Digest? lastKnownDigest}) =>
      AssetNode(
        (b) =>
            b
              ..id = id
              ..type = NodeType.builderOptions
              ..lastKnownDigest = lastKnownDigest,
      );

  /// A missing source file.
  ///
  /// Created when a builder tries to read a non-existent file.
  ///
  /// If later the file does exist, the builder must be rerun as it can
  /// produce different output.
  factory AssetNode.missingSource(AssetId id, {Digest? lastKnownDigest}) =>
      AssetNode(
        (b) =>
            b
              ..id = id
              ..type = NodeType.syntheticSource
              ..lastKnownDigest = lastKnownDigest,
      );

  /// Placeholders for useful parts of packages.
  ///
  /// Four types of placeholder are used per package: the `lib` folder, the
  /// `test` folder, the `web` folder, and the whole package.
  ///
  /// TODO(davidmorgan): describe how these are used.
  factory AssetNode.placeholder(AssetId id, {Digest? lastKnownDigest}) =>
      AssetNode(
        (b) =>
            b
              ..id = id
              ..type = NodeType.placeholder
              ..lastKnownDigest = lastKnownDigest,
      );

  /// A generated node.
  factory AssetNode.generated(
    AssetId id, {
    Digest? lastKnownDigest,
    required AssetId primaryInput,
    required AssetId builderOptionsId,
    required int phaseNumber,
    required bool isHidden,
    Iterable<AssetId>? inputs,
    Digest? previousInputsDigest,
    required PendingBuildAction pendingBuildAction,
    required bool wasOutput,
    required bool isFailure,
  }) => AssetNode(
    (b) =>
        b
          ..id = id
          ..type = NodeType.generated
          ..configuration = GeneratedNodeConfiguration(
            (b) =>
                b
                  ..primaryInput = primaryInput
                  ..builderOptionsId = builderOptionsId
                  ..phaseNumber = phaseNumber
                  ..isHidden = isHidden,
          )
          ..state = GeneratedNodeState(
            (b) =>
                b
                  ..inputs.replace(inputs ?? [])
                  ..previousInputsDigest = previousInputsDigest
                  ..pendingBuildAction = pendingBuildAction
                  ..wasOutput = wasOutput
                  ..isFailure = isFailure,
          )
          ..lastKnownDigest = lastKnownDigest,
  );

  /// A glob node.
  factory AssetNode.glob(
    AssetId id, {
    Digest? lastKnownDigest,
    required Glob glob,
    required int phaseNumber,
    Iterable<AssetId>? inputs,
    required PendingBuildAction pendingBuildAction,
    List<AssetId>? results,
  }) => AssetNode(
    (b) =>
        b
          ..id = id
          ..type = NodeType.glob
          ..configuration = GlobNodeConfiguration(
            (b) =>
                b
                  ..glob = glob
                  ..phaseNumber = phaseNumber,
          )
          ..state = GlobNodeState(
            (b) =>
                b
                  ..pendingBuildAction = pendingBuildAction
                  ..results.replace(results ?? []),
          )
          ..lastKnownDigest = lastKnownDigest,
  );

  static AssetId createGlobNodeId(String package, Glob glob, int phaseNum) =>
      AssetId(
        package,
        'glob.$phaseNum.${base64.encode(utf8.encode(glob.pattern))}',
      );

  /// A [primaryInput] to a [PostBuildAction].
  ///
  /// The [outputs] of this node are the individual outputs created for the
  /// [primaryInput] during the [PostBuildAction] at index [actionNumber].
  factory AssetNode.postProcessAnchor(
    AssetId id, {
    required AssetId primaryInput,
    required int actionNumber,
    required AssetId builderOptionsId,
    Digest? previousInputsDigest,
  }) => AssetNode(
    (b) =>
        b
          ..id = id
          ..type = NodeType.postProcessAnchor
          ..configuration = PostProcessAnchorNodeConfiguration(
            (b) =>
                b
                  ..actionNumber = actionNumber
                  ..builderOptionsId = builderOptionsId
                  ..primaryInput = primaryInput,
          )
          ..state = PostProcessAnchorNodeState(
            (b) => b..previousInputsDigest = previousInputsDigest,
          ),
  );

  factory AssetNode.postProcessAnchorForInputAndAction(
    AssetId primaryInput,
    int actionNumber,
    AssetId builderOptionsId,
  ) => AssetNode.postProcessAnchor(
    primaryInput.addExtension('.post_anchor.$actionNumber'),
    primaryInput: primaryInput,
    actionNumber: actionNumber,
    builderOptionsId: builderOptionsId,
  );

  AssetNode._();

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

abstract class AssetNodeBuilder
    implements Builder<AssetNode, AssetNodeBuilder> {
  AssetId? id;
  NodeType? type;
  AdditionalNodeConfigurationBuilder? configuration;
  AdditionalNodeStateBuilder? state;
  SetBuilder<AssetId> primaryOutputs = SetBuilder();
  SetBuilder<AssetId> outputs = SetBuilder();
  SetBuilder<AssetId> anchorOutputs = SetBuilder();
  Digest? lastKnownDigest;
  SetBuilder<AssetId> deletedBy = SetBuilder();

  AssetNodeBuilder._();
  factory AssetNodeBuilder() = _$AssetNodeBuilder;

  GeneratedNodeConfigurationBuilder get generatedNodeConfiguration =>
      configuration as GeneratedNodeConfigurationBuilder;
  GeneratedNodeStateBuilder get generatedNodeState =>
      state as GeneratedNodeStateBuilder;

  GlobNodeConfigurationBuilder get globNodeConfiguration =>
      configuration as GlobNodeConfigurationBuilder;
  GlobNodeStateBuilder get globNodeState => state as GlobNodeStateBuilder;

  PostProcessAnchorNodeConfigurationBuilder
  get postProcessAnchorNodeConfiguration =>
      configuration as PostProcessAnchorNodeConfigurationBuilder;
  PostProcessAnchorNodeStateBuilder get postProcessAnchorNodeState =>
      state as PostProcessAnchorNodeStateBuilder;
}

/// Additional immutable configuration for some node types.
@BuiltValue(instantiable: false)
abstract class AdditionalNodeConfiguration {}

/// Additional mutable state for some node types.
@BuiltValue(instantiable: false)
abstract interface class AdditionalNodeState {}

/// Additional configuration for an [AssetNode.generated].
abstract class GeneratedNodeConfiguration
    implements
        Built<GeneratedNodeConfiguration, GeneratedNodeConfigurationBuilder>,
        AdditionalNodeConfiguration {
  /// The primary input which generated this node.
  AssetId get primaryInput;

  /// The [AssetId] of the node representing the [BuilderOptions] used to create
  /// this node.
  AssetId get builderOptionsId;

  /// The phase in which this node is generated.
  ///
  /// The generator that produces this node can only read files from earlier
  /// phases plus any files it writes itself.
  ///
  /// Other generators and globs can only read this node if they run in a
  /// later phase.
  int get phaseNumber;

  /// Whether the asset should be placed in the build cache.
  bool get isHidden;

  factory GeneratedNodeConfiguration(
    void Function(GeneratedNodeConfigurationBuilder) updates,
  ) = _$GeneratedNodeConfiguration;

  GeneratedNodeConfiguration._();
}

/// State for an [AssetNode.generated] that changes during the build.
abstract class GeneratedNodeState
    implements
        Built<GeneratedNodeState, GeneratedNodeStateBuilder>,
        AdditionalNodeState {
  /// All the inputs that were read when generating this asset, or deciding not
  /// to generate it.
  BuiltSet<AssetId> get inputs;

  /// The next work that needs doing on this node.
  PendingBuildAction get pendingBuildAction;

  /// Whether the asset was actually output.
  bool get wasOutput;

  /// Whether the action which did or would produce this node failed.
  bool get isFailure;

  /// A digest combining all digests of all previous inputs.
  ///
  /// Used to determine whether all the inputs to a build step are identical to
  /// the previous run, indicating that the previous output is still valid.
  Digest? get previousInputsDigest;

  bool get isSuccessfulFreshOutput =>
      wasOutput && !isFailure && pendingBuildAction == PendingBuildAction.none;

  factory GeneratedNodeState(void Function(GeneratedNodeStateBuilder) updates) =
      _$GeneratedNodeState;

  GeneratedNodeState._();
}

/// Additional configuration for an [AssetNode.glob].
abstract class GlobNodeConfiguration
    implements
        Built<GlobNodeConfiguration, GlobNodeConfigurationBuilder>,
        AdditionalNodeConfiguration {
  Glob get glob;
  int get phaseNumber;

  factory GlobNodeConfiguration(
    void Function(GlobNodeConfigurationBuilder) updates,
  ) = _$GlobNodeConfiguration;

  GlobNodeConfiguration._();
}

/// State for an [AssetNode.glob] that changes during the build.
abstract class GlobNodeState
    implements Built<GlobNodeState, GlobNodeStateBuilder>, AdditionalNodeState {
  /// All the potential inputs matching this glob.
  ///
  /// This field differs from [results] in that [AssetNode.generated] which may
  /// have been readable but were not output are included here and not in
  /// [results].
  BuiltSet<AssetId> get inputs;

  PendingBuildAction get pendingBuildAction;

  /// The results of the glob, valid when [pendingBuildAction] is
  /// [PendingBuildAction.none].
  BuiltList<AssetId> get results;

  factory GlobNodeState(void Function(GlobNodeStateBuilder) updates) =
      _$GlobNodeState;

  GlobNodeState._();
}

// Additional configuration for an [AssetNode.postProcessAnchor].
abstract class PostProcessAnchorNodeConfiguration
    implements
        Built<
          PostProcessAnchorNodeConfiguration,
          PostProcessAnchorNodeConfigurationBuilder
        >,
        AdditionalNodeConfiguration {
  int get actionNumber;
  AssetId get builderOptionsId;
  AssetId get primaryInput;

  PostProcessAnchorNodeConfiguration._();

  factory PostProcessAnchorNodeConfiguration(
    void Function(PostProcessAnchorNodeConfigurationBuilder) updates,
  ) = _$PostProcessAnchorNodeConfiguration;
}

/// State for an [AssetNode.postProcessAnchor].
abstract class PostProcessAnchorNodeState
    implements
        Built<PostProcessAnchorNodeState, PostProcessAnchorNodeStateBuilder>,
        AdditionalNodeState {
  Digest? get previousInputsDigest;

  factory PostProcessAnchorNodeState(
    void Function(PostProcessAnchorNodeStateBuilder) updates,
  ) = _$PostProcessAnchorNodeState;

  PostProcessAnchorNodeState._();
}

/// Write access to collections in the node.
///
/// This allows the same access as if they were directly exposed, but makes it
/// easy to search the code for mutates.
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

/// Work that needs doing for a node that tracks its inputs.
class PendingBuildAction extends EnumClass {
  static const PendingBuildAction none = _$none;
  static const PendingBuildAction buildIfInputsChanged = _$buildIfInputsChanged;
  static const PendingBuildAction build = _$build;

  const PendingBuildAction._(super.name);

  static BuiltSet<PendingBuildAction> get values => _$pendingBuildActionValues;
  static PendingBuildAction valueOf(String name) =>
      _$pendingBuildActionValueOf(name);
}
