// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import '../asset/id.dart';

/// A node in the asset graph.
///
/// This class specifically represents normal (ie: non-generated) assets.
class AssetNode {
  /// The asset this node represents.
  final AssetId id;

  /// The [AssetId]s of all generated assets which depend on this node.
  final Set<AssetId> outputs = new Set<AssetId>();

  AssetNode(this.id);

  factory AssetNode.deserialize(List serializedNode) {
    var node;
    if (serializedNode.length == 2) {
      node = new AssetNode(new AssetId.deserialize(serializedNode[0]));
    } else if (serializedNode.length == 4) {
      node = new GeneratedAssetNode.deserialize(serializedNode);
    } else {
      throw new ArgumentError(
          'Unrecognized serialization format! $serializedNode');
    }

    node.outputs.addAll(serializedNode[1]
        .map((serializedOutput) => new AssetId.deserialize(serializedOutput)));
    return node;
  }

  List serialize() =>
      [id.serialize(), outputs.map((id) => id.serialize()).toList()];

  @override
  String toString() => 'AssetNode: $id';
}

/// A generated node in the asset graph.
class GeneratedAssetNode extends AssetNode {
  /// The primary input which generated this node.
  final AssetId primaryInput;

  /// Whether or not this asset needs to be updated.
  bool needsUpdate;

  /// Whether the asset was actually output.
  bool wasOutput;

  GeneratedAssetNode(
      this.primaryInput, this.needsUpdate, this.wasOutput, AssetId id)
      : super(id);

  factory GeneratedAssetNode.deserialize(List serialized) {
    var node = new GeneratedAssetNode(new AssetId.deserialize(serialized[2]),
        false, serialized[3], new AssetId.deserialize(serialized[0]));
    node.outputs.addAll((serialized[1] as Iterable)
        .map((serializedOutput) => new AssetId.deserialize(serializedOutput)));
    return node;
  }

  @override
  List serialize() =>
      super.serialize()..addAll([primaryInput.serialize(), wasOutput]);

  @override
  String toString() =>
      'GeneratedAssetNode: $id generated from input $primaryInput.';
}
