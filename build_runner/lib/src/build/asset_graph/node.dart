// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:build/build.dart' hide Builder;
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:crypto/crypto.dart';

import 'post_process_build_step_id.dart';

part 'node.g.dart';

/// Types of [AssetNode].
class NodeType extends EnumClass {
  static Serializer<NodeType> get serializer => _$nodeTypeSerializer;

  static const NodeType generated = _$generated;
  static const NodeType glob = _$glob;
  static const NodeType placeholder = _$placeholder;
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

  /// The assets that any [Builder] in the build graph declares it may output
  /// when run on this asset.
  // TODO(davidmorgan): remove and compute when needed?
  BuiltSet<AssetId> get primaryOutputs;

  /// The [Digest] for this node.
  ///
  /// For source files, this is computed when the file is read so it can be used
  /// to check for changes in the next build.
  ///
  /// For generated files, it's computed and set when the file is output, at the
  /// same time comparing with any previous value to check if the output has
  /// changed since the previous build. Here, `null` means "not output".
  ///
  /// For globs, it's computed and set when the glob is evaluated, at the same
  /// time comparing with any previous value to check if the glob results have
  /// changed.
  ///
  /// For other node types, `null`.
  Digest? get digest;

  /// The `PostProcessBuildStep`s which requested to delete this asset.
  BuiltSet<PostProcessBuildStepId> get deletedBy;

  /// Whether this asset is a normal, readable file.
  ///
  /// Does not guarantee that the file currently exists.
  bool get isFile => type == NodeType.generated || type == NodeType.source;

  /// Whether this node is tracked as an input in the asset graph.
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
      type == NodeType.glob || type == NodeType.missingSource || digest != null;

  factory AssetNode([void Function(AssetNodeBuilder) updates]) = _$AssetNode;

  /// A manually-written source file.
  factory AssetNode.source(
    AssetId id, {
    Digest? digest,
    Iterable<AssetId>? outputs,
    Iterable<AssetId>? primaryOutputs,
  }) => AssetNode((b) {
    b.id = id;
    b.type = NodeType.source;
    b.primaryOutputs.replace(primaryOutputs ?? {});
    b.digest = digest;
  });

  /// A missing source file.
  ///
  /// Created when a builder tries to read a non-existent file.
  ///
  /// If later the file does exist, the builder must be rerun as it can
  /// produce different output.
  factory AssetNode.missingSource(AssetId id) => AssetNode((b) {
    b.id = id;
    b.type = NodeType.missingSource;
  });

  /// Placeholders for useful parts of packages.
  ///
  /// Four types of placeholder are used per package: the `lib` folder, the
  /// `test` folder, the `web` folder, and the whole package.
  ///
  /// TODO(davidmorgan): describe how these are used.
  factory AssetNode.placeholder(AssetId id) => AssetNode((b) {
    b.id = id;
    b.type = NodeType.placeholder;
  });

  /// A generated node.
  factory AssetNode.generated(
    AssetId id, {
    Digest? digest,
    required AssetId primaryInput,
    required int phaseNumber,
    required bool isHidden,
    Iterable<AssetId>? inputs,
    bool? result,
  }) => AssetNode((b) {
    b.id = id;
    b.type = NodeType.generated;
    b.generatedNodeConfiguration.primaryInput = primaryInput;
    b.generatedNodeConfiguration.phaseNumber = phaseNumber;
    b.generatedNodeConfiguration.isHidden = isHidden;
    b.generatedNodeState.inputs.replace(inputs ?? []);
    b.generatedNodeState.result = result;
    b.digest = digest;
  });

  /// A glob node.
  factory AssetNode.glob(
    AssetId id, {
    required String glob,
    required int phaseNumber,
    Iterable<AssetId>? inputs,
    List<AssetId>? results,
  }) => AssetNode((b) {
    b.id = id;
    b.type = NodeType.glob;
    b.globNodeConfiguration.glob = glob;
    b.globNodeConfiguration.phaseNumber = phaseNumber;
    b.globNodeState.results.replace(results ?? []);
  });

  static AssetId createGlobNodeId(String package, String glob, int phaseNum) =>
      AssetId(package, 'glob.$phaseNum.${base64.encode(utf8.encode(glob))}');

  AssetNode._() {
    // Check that configuration and state fields are non-null exactly when the
    // node is of the corresponding type.

    void check(bool hasType, bool hasConfiguration, [bool? hasState]) {
      if (hasType != hasConfiguration) {
        throw ArgumentError(
          'Node configuration does not match its type: $this',
        );
      }
      if (hasState != null && hasType != hasState) {
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
  }

  /// The generated node inputs, or the glob node inputs, or `null` if the node
  /// is not of one of those two types.
  BuiltSet<AssetId>? get inputs {
    switch (type) {
      case NodeType.generated:
        return generatedNodeState!.inputs;
      case NodeType.glob:
        return globNodeState!.inputs;
      default:
        return null;
    }
  }

  /// Whether this is a generated node that was written when the generator ran.
  ///
  /// A file can be output by a failing generator, check
  /// `generatedNodeState.result` for whether the generator succeeded.
  bool get wasOutput => type == NodeType.generated && digest != null;
}

/// Additional configuration for an [AssetNode.generated].
abstract class GeneratedNodeConfiguration
    implements
        Built<GeneratedNodeConfiguration, GeneratedNodeConfigurationBuilder> {
  static Serializer<GeneratedNodeConfiguration> get serializer =>
      _$generatedNodeConfigurationSerializer;

  /// The primary input which generated this node.
  AssetId get primaryInput;

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

  /// Entrypoints used for resolution with the analyzer.
  BuiltSet<AssetId> get resolverEntrypoints;

  /// Whether the generation succeded, or `null` if it did not run.
  ///
  /// A full build can complete with `null` results if there are optional
  /// outputs that are not depended on by required outputs.
  ///
  /// Generation can succeed without writing the output: see
  /// [AssetNode.wasOutput].
  bool? get result;

  BuiltList<String> get errors;

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

  /// The results of the glob.
  BuiltList<AssetId> get results;

  factory GlobNodeState(void Function(GlobNodeStateBuilder) updates) =
      _$GlobNodeState;

  GlobNodeState._();
}
