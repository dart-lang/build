// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'graph.dart';

/// Deserializes an [AssetGraph] from a [Map].
class _AssetGraphDeserializer {
  final _idToAssetId = <int, AssetId>{};
  final Map _serializedGraph;

  _AssetGraphDeserializer(this._serializedGraph);

  /// Perform the deserialization, should only be called once.
  AssetGraph deserialize() {
    if (_serializedGraph['version'] != AssetGraph._version) {
      throw new AssetGraphVersionException(
          _serializedGraph['version'] as int, AssetGraph._version);
    }

    var graph = new AssetGraph._();

    // Read in the id => AssetId map from the graph first.
    for (var descriptor in _serializedGraph['serializedAssetIds']) {
      _idToAssetId[descriptor[0] as int] =
          new AssetId(descriptor[1] as String, descriptor[2] as String);
    }

    for (var serializedItem in _serializedGraph['nodes']) {
      graph._add(_deserializeAssetNode(serializedItem as List));
    }

    graph.validAsOf = new DateTime.fromMillisecondsSinceEpoch(
        _serializedGraph['validAsOf'] as int);
    return graph;
  }

  AssetNode _deserializeAssetNode(List serializedNode) {
    AssetNode node;
    if (serializedNode.length == 3) {
      node = new AssetNode(_idToAssetId[serializedNode[0]]);
    } else if (serializedNode.length == 8) {
      node = new GeneratedAssetNode(
        serializedNode[5] as int,
        _idToAssetId[serializedNode[3]],
        _deserializeBool(serializedNode[7] as int),
        _deserializeBool(serializedNode[4] as int),
        _idToAssetId[serializedNode[0]],
        globs: (serializedNode[6] as Iterable<String>)
            .map((pattern) => new Glob(pattern))
            .toSet(),
      );
    } else {
      throw new ArgumentError(
          'Unrecognized serialization format! $serializedNode');
    }
    node.outputs.addAll(_deserializeAssetIds(serializedNode[1] as List<int>));
    node.primaryOutputs
        .addAll(_deserializeAssetIds(serializedNode[2] as List<int>));
    return node;
  }

  List<AssetId> _deserializeAssetIds(List<int> serializedIds) =>
      serializedIds.map((id) => _idToAssetId[id]).toList();

  bool _deserializeBool(int value) => value == 0 ? false : true;
}

/// Serializes an [AssetGraph] into a [Map].
class _AssetGraphSerializer {
  final _assetIdToId = <AssetId, int>{};

  final AssetGraph _graph;

  _AssetGraphSerializer(this._graph);

  /// Perform the serialization, should only be called once.
  Map<String, dynamic> serialize() {
    /// Compute numeric identifiers for all asset ids.
    var next = 0;
    for (var node in _graph.allNodes) {
      _assetIdToId[node.id] = next;
      next++;
    }

    var result = <String, dynamic>{
      'version': AssetGraph._version,
      'nodes': _graph.allNodes.map(_serializeNode).toList(),
      'validAsOf': _graph.validAsOf.millisecondsSinceEpoch,
    };

    // Store the id => AssetId mapping as a nested list so we don't have to
    // stringify the integers and parse them back (ints aren't valid JSON
    // keys).
    var serializedAssetIds = <List>[];
    _assetIdToId.forEach((k, v) {
      serializedAssetIds.add([v, k.package, k.path]);
    });
    result['serializedAssetIds'] = serializedAssetIds;

    return result;
  }

  List _serializeNode(AssetNode node) {
    if (node is GeneratedAssetNode) {
      return new _WrappedGeneratedAssetNode(node, this);
    } else {
      return new _WrappedAssetNode(node, this);
    }
  }
}

/// Wraps an [AssetNode] in a class that implements [List] instead of
/// creating a new list for each one.
class _WrappedAssetNode extends Object with ListMixin implements List {
  final AssetNode node;
  final _AssetGraphSerializer serializer;

  _WrappedAssetNode(this.node, this.serializer);

  @override
  int get length => 3;
  @override
  set length(_) => throw new UnsupportedError(
      'length setter not unsupported for WrappedAssetNode');

  @override
  Object operator [](int index) {
    switch (index) {
      case 0:
        return serializer._assetIdToId[node.id];
      case 1:
        return node.outputs.map((id) => serializer._assetIdToId[id]).toList();
      case 2:
        return node.primaryOutputs
            .map((id) => serializer._assetIdToId[id])
            .toList();
      default:
        throw new RangeError.index(index, this);
    }
  }

  @override
  operator []=(_, __) =>
      throw new UnsupportedError('[]= not supported for WrappedAssetNode');
}

/// Wraps a [GeneratedAssetNode] in a class that implements [List] instead of
/// creating a new list for each one.
class _WrappedGeneratedAssetNode extends _WrappedAssetNode {
  final GeneratedAssetNode generatedNode;

  @override
  int get length => super.length + 5;

  _WrappedGeneratedAssetNode(
      this.generatedNode, _AssetGraphSerializer serializer)
      : super(generatedNode, serializer);

  @override
  Object operator [](int index) {
    if (index < super.length) return super[index];
    switch (index) {
      case 3:
        return generatedNode.primaryInput != null
            ? serializer._assetIdToId[generatedNode.primaryInput]
            : null;
      case 4:
        return _serializeBool(generatedNode.wasOutput);
      case 5:
        return generatedNode.phaseNumber;
      case 6:
        return generatedNode.globs.map((glob) => glob.pattern).toList();
      case 7:
        return _serializeBool(generatedNode.needsUpdate);
      default:
        throw new RangeError.index(index, this);
    }
  }

  static int _serializeBool(bool value) => value ? 1 : 0;
}
