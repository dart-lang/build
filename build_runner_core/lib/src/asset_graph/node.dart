// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:build/build.dart' hide Builder;
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:crypto/crypto.dart';

import '../generate/phase.dart';

part 'node.g.dart';

/// Types of [AssetNode].
class NodeType extends EnumClass {
  static Serializer<NodeType> get serializer => _$nodeTypeSerializer;

  static const NodeType builderOptions = _$builderOptions;
  static const NodeType generated = _$generated;
  static const NodeType glob = _$glob;
  static const NodeType internal = _$internal;
  static const NodeType placeholder = _$placeholder;
  static const NodeType postProcessAnchor = _$postProcessAnchor;
  static const NodeType source = _$source;
  static const NodeType missingSource = _$missingSource;

  const NodeType._(super.name);

  static BuiltSet<NodeType> get values => _$nodeTypeValues;
  static NodeType valueOf(String name) => _$nodeTypeValueOf(name);
}

/// A node in the asset graph which may be an input to other assets.
abstract class AssetNode implements Built<AssetNode, AssetNodeBuilder> {
  static Serializer<AssetNode> get serializer => _$assetNodeSerializer;

  AssetId get id;
  NodeType get type;

  /// Additional node configuration for an [AssetNode.generated].
  GeneratedNodeConfiguration? get generatedNodeConfiguration;

  /// Additional node state that changes during the build for an
  /// [AssetNode.generated].
  GeneratedNodeState? get generatedNodeState;

  /// Additional node configuration for an [AssetNode.glob].
  GlobNodeConfiguration? get globNodeConfiguration;

  /// Additional node state that changes during the build for an
  /// [AssetNode.glob].
  GlobNodeState? get globNodeState;

  /// Additional node configuration for an
  /// [AssetNode.postProcessAnchorNodeConfiguration].
  PostProcessAnchorNodeConfiguration? get postProcessAnchorNodeConfiguration;

  /// Additional node state that changes during the build for an
  /// [AssetNode.postProcessAnchor].
  PostProcessAnchorNodeState? get postProcessAnchorNodeState;

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
              ..type = NodeType.missingSource
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
    required PendingBuildAction pendingBuildAction,
    required bool wasOutput,
    required bool isFailure,
  }) => AssetNode(
    (b) =>
        b
          ..id = id
          ..type = NodeType.generated
          ..generatedNodeConfiguration.primaryInput = primaryInput
          ..generatedNodeConfiguration.builderOptionsId = builderOptionsId
          ..generatedNodeConfiguration.phaseNumber = phaseNumber
          ..generatedNodeConfiguration.isHidden = isHidden
          ..generatedNodeState.inputs.replace(inputs ?? [])
          ..generatedNodeState.pendingBuildAction = pendingBuildAction
          ..generatedNodeState.wasOutput = wasOutput
          ..generatedNodeState.isFailure = isFailure
          ..lastKnownDigest = lastKnownDigest,
  );

  /// A glob node.
  factory AssetNode.glob(
    AssetId id, {
    Digest? lastKnownDigest,
    required String glob,
    required int phaseNumber,
    Iterable<AssetId>? inputs,
    required PendingBuildAction pendingBuildAction,
    List<AssetId>? results,
  }) => AssetNode(
    (b) =>
        b
          ..id = id
          ..type = NodeType.glob
          ..globNodeConfiguration.glob = glob
          ..globNodeConfiguration.phaseNumber = phaseNumber
          ..globNodeState.pendingBuildAction = pendingBuildAction
          ..globNodeState.results.replace(results ?? [])
          ..lastKnownDigest = lastKnownDigest,
  );

  static AssetId createGlobNodeId(String package, String glob, int phaseNum) =>
      AssetId(package, 'glob.$phaseNum.${base64.encode(utf8.encode(glob))}');

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
          ..postProcessAnchorNodeConfiguration.actionNumber = actionNumber
          ..postProcessAnchorNodeConfiguration.builderOptionsId =
              builderOptionsId
          ..postProcessAnchorNodeConfiguration.primaryInput = primaryInput
          ..postProcessAnchorNodeState.previousInputsDigest =
              previousInputsDigest,
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

  AssetNode._() {
    // Check that configuration and state fields are non-null exactly when the
    // node is of the corresponding type.

    void check(bool hasType, bool hasConfiguration, bool hasState) {
      if (hasType != hasConfiguration) {
        throw ArgumentError(
          'Node configuration does not match its type: $this',
        );
      }
      if (hasType != hasState) {
        throw ArgumentError('Node state does not match its type: $this');
      }
    }

    check(
      type == NodeType.generated,
      generatedNodeConfiguration != null,
      generatedNodeState != null,
    );
    check(
      type == NodeType.glob,
      globNodeConfiguration != null,
      globNodeState != null,
    );
    check(
      type == NodeType.postProcessAnchor,
      postProcessAnchorNodeConfiguration != null,
      postProcessAnchorNodeState != null,
    );
  }
}

/// Additional configuration for an [AssetNode.generated].
abstract class GeneratedNodeConfiguration
    implements
        Built<GeneratedNodeConfiguration, GeneratedNodeConfigurationBuilder> {
  static Serializer<GeneratedNodeConfiguration> get serializer =>
      _$generatedNodeConfigurationSerializer;

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
    implements Built<GeneratedNodeState, GeneratedNodeStateBuilder> {
  static Serializer<GeneratedNodeState> get serializer =>
      _$generatedNodeStateSerializer;

  /// All the inputs that were read when generating this asset, or deciding not
  /// to generate it.
  BuiltSet<AssetId> get inputs;

  /// The next work that needs doing on this node.
  PendingBuildAction get pendingBuildAction;

  /// Whether the asset was actually output.
  bool get wasOutput;

  /// Whether the action which did or would produce this node failed.
  bool get isFailure;

  bool get isSuccessfulFreshOutput =>
      wasOutput && !isFailure && pendingBuildAction == PendingBuildAction.none;

  factory GeneratedNodeState(void Function(GeneratedNodeStateBuilder) updates) =
      _$GeneratedNodeState;

  GeneratedNodeState._();
}

/// Additional configuration for an [AssetNode.glob].
abstract class GlobNodeConfiguration
    implements Built<GlobNodeConfiguration, GlobNodeConfigurationBuilder> {
  static Serializer<GlobNodeConfiguration> get serializer =>
      _$globNodeConfigurationSerializer;

  String get glob;
  int get phaseNumber;

  factory GlobNodeConfiguration(
    void Function(GlobNodeConfigurationBuilder) updates,
  ) = _$GlobNodeConfiguration;

  GlobNodeConfiguration._();
}

/// State for an [AssetNode.glob] that changes during the build.
abstract class GlobNodeState
    implements Built<GlobNodeState, GlobNodeStateBuilder> {
  static Serializer<GlobNodeState> get serializer => _$globNodeStateSerializer;

  /// The next work that needs doing on this node.

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
        > {
  static Serializer<PostProcessAnchorNodeConfiguration> get serializer =>
      _$postProcessAnchorNodeConfigurationSerializer;

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
        Built<PostProcessAnchorNodeState, PostProcessAnchorNodeStateBuilder> {
  static Serializer<PostProcessAnchorNodeState> get serializer =>
      _$postProcessAnchorNodeStateSerializer;

  Digest? get previousInputsDigest;

  factory PostProcessAnchorNodeState(
    void Function(PostProcessAnchorNodeStateBuilder) updates,
  ) = _$PostProcessAnchorNodeState;

  PostProcessAnchorNodeState._();
}

/// Work that needs doing for a node that tracks its inputs.
class PendingBuildAction extends EnumClass {
  static Serializer<PendingBuildAction> get serializer =>
      _$pendingBuildActionSerializer;

  static const PendingBuildAction none = _$none;
  static const PendingBuildAction buildIfInputsChanged = _$buildIfInputsChanged;
  static const PendingBuildAction build = _$build;

  const PendingBuildAction._(super.name);

  static BuiltSet<PendingBuildAction> get values => _$pendingBuildActionValues;
  static PendingBuildAction valueOf(String name) =>
      _$pendingBuildActionValueOf(name);
}

@SerializersFor([AssetNode])
final Serializers serializers =
    (_$serializers.toBuilder()
          ..add(AssetIdSerializer())
          ..add(DigestSerializer()))
        .build();

/// Serializer for [AssetId].
///
/// It would also work to make `AssetId` a `built_value` class, but there's
/// little benefit and it's nicer to keep codegen local to this package.
class AssetIdSerializer implements PrimitiveSerializer<AssetId> {
  @override
  Iterable<Type> get types => [AssetId];

  @override
  String get wireName => 'AssetId';

  @override
  AssetId deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => AssetId.parse(serialized as String);

  @override
  Object serialize(
    Serializers serializers,
    AssetId object, {
    FullType specifiedType = FullType.unspecified,
  }) => object.toString();
}

/// Serializer for [Digest].
class DigestSerializer implements PrimitiveSerializer<Digest> {
  @override
  Iterable<Type> get types => [Digest];

  @override
  String get wireName => 'Digest';

  @override
  Digest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => Digest(base64.decode(serialized as String));

  @override
  Object serialize(
    Serializers serializers,
    Digest object, {
    FullType specifiedType = FullType.unspecified,
  }) => base64.encode(object.bytes);
}
