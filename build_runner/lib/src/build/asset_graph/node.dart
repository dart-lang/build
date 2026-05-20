// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart' hide Builder;
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:crypto/crypto.dart';

part 'node.g.dart';

/// Types of [AssetNode].
class NodeType extends EnumClass {
  static Serializer<NodeType> get serializer => _$nodeTypeSerializer;

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

  /// The [Digest] for this node.
  ///
  /// For source files, this is computed when the file is read so it can be used
  /// to check for changes in the next build.
  Digest? get digest;

  factory AssetNode([void Function(AssetNodeBuilder) updates]) = _$AssetNode;

  /// A manually-written source file.
  factory AssetNode.source(AssetId id, {Digest? digest}) => AssetNode((b) {
    b.id = id;
    b.type = NodeType.source;
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

  AssetNode._();
}
