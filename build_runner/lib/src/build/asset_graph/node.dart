// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart' hide Builder;
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:crypto/crypto.dart';

import 'build_step_id.dart';

part 'node.g.dart';

/// Types of [AssetNode].
class NodeType extends EnumClass {
  static Serializer<NodeType> get serializer => _$nodeTypeSerializer;

  static const NodeType generated = _$generated;
  static const NodeType postGenerated = _$postGenerated;
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

  /// The assets that any [Builder] in the build graph declares it may output
  /// when run on this asset.
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
  /// For other node types, `null`.
  Digest? get digest;

  /// Whether this asset is a normal, readable file.
  ///
  /// Does not guarantee that the file currently exists.
  bool get isFile =>
      type == NodeType.generated ||
      type == NodeType.postGenerated ||
      type == NodeType.source;

  factory AssetNode([void Function(AssetNodeBuilder) updates]) = _$AssetNode;

  /// A manually-written source file.
  factory AssetNode.source(
    AssetId id, {
    Digest? digest,
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
  }) => AssetNode((b) {
    b.id = id;
    b.type = NodeType.generated;
    b.generatedNodeConfiguration.primaryInput = primaryInput;
    b.generatedNodeConfiguration.phaseNumber = phaseNumber;
    b.generatedNodeConfiguration.isHidden = isHidden;
    b.digest = digest;
  });

  /// A post-process generated node.
  factory AssetNode.postGenerated(AssetId id) => AssetNode((b) {
    b.id = id;
    b.type = NodeType.postGenerated;
  });

  AssetNode._() {
    if ((type == NodeType.generated) != (generatedNodeConfiguration != null)) {
      throw ArgumentError('Node configuration does not match its type: $this');
    }
  }

  bool get isGenerated =>
      type == NodeType.generated || type == NodeType.postGenerated;

  /// Whether this is a generated node that was written when the generator ran.
  ///
  /// A file can be output by a failing generator, check
  /// `generatedNodeState.result` for whether the generator succeeded.
  bool get wasOutput =>
      type == NodeType.postGenerated ||
      (type == NodeType.generated && digest != null);
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

  BuildStepId get buildStepId =>
      BuildStepId(primaryInput: primaryInput, phaseNumber: phaseNumber);

  factory GeneratedNodeConfiguration(
    void Function(GeneratedNodeConfigurationBuilder) updates,
  ) = _$GeneratedNodeConfiguration;

  GeneratedNodeConfiguration._();
}
