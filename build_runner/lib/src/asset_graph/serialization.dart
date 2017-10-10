// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'graph.dart';

class _AssetGraphDeserializer {
  final _idToAssetId = <int, AssetId>{};
  final Map _serializedGraph;

  _AssetGraphDeserializer(this._serializedGraph);

  AssetGraph deserialize() {
    if (_serializedGraph['version'] != AssetGraph._version) {
      throw new AssetGraphVersionException(
          _serializedGraph['version'] as int, AssetGraph._version);
    }

    var graph = new AssetGraph._();

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

class _AssetGraphSerializer {
  final _assetIdToId = <AssetId, int>{};

  final AssetGraph _graph;

  _AssetGraphSerializer(this._graph);

  Map<String, dynamic> serialize() {
    /// Compute numeric ids for all nodes.
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

    var serializedAssetIds = <List>[];
    _assetIdToId.forEach((k, v) {
      serializedAssetIds.add([v, k.package, k.path]);
    });
    result['serializedAssetIds'] = serializedAssetIds;
    return result;
  }

  List<Object> _serializeNode(AssetNode node) {
    var serializedNode = <Object>[
      _assetIdToId[node.id],
      node.outputs.map((id) => _assetIdToId[id]).toList(),
      node.primaryOutputs.map((id) => _assetIdToId[id]).toList(),
    ];

    if (node is GeneratedAssetNode) {
      serializedNode.addAll([
        _assetIdToId[node.primaryInput],
        _serializeBool(node.wasOutput),
        node.phaseNumber,
        node.globs.map((glob) => glob.pattern).toList(),
        _serializeBool(node.needsUpdate),
      ]);
    }

    return serializedNode;
  }

  int _serializeBool(bool value) => value ? 1 : 0;
}
