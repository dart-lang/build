// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'graph.dart';

/// Part of the serialized graph, used to ensure versioning constraints.
///
/// This should be incremented any time the serialize/deserialize formats
/// change.
const _version = 9;

/// Deserializes an [AssetGraph] from a [Map].
class _AssetGraphDeserializer {
  final _idToAssetId = <int, AssetId>{};
  final Map _serializedGraph;

  _AssetGraphDeserializer(this._serializedGraph);

  /// Perform the deserialization, should only be called once.
  AssetGraph deserialize() {
    if (_serializedGraph['version'] != _version) {
      throw new AssetGraphVersionException(
          _serializedGraph['version'] as int, _version);
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
    var typeId =
        _NodeTypeId.values[serializedNode[_FieldId.NodeType.index] as int];
    var id = _idToAssetId[serializedNode[_FieldId.Id.index] as int];
    var serializedDigest = serializedNode[_FieldId.Digest.index] as String;
    var digest = serializedDigest == null
        ? null
        : new Digest(BASE64.decode(serializedDigest));
    switch (typeId) {
      case _NodeTypeId.Source:
        assert(serializedNode.length == _WrappedAssetNode._length);
        node = new SourceAssetNode(id, lastKnownDigest: digest);
        break;
      case _NodeTypeId.Synthetic:
        assert(serializedNode.length == _WrappedAssetNode._length);
        node = new SyntheticAssetNode(id);
        break;
      case _NodeTypeId.Generated:
        assert(serializedNode.length == _WrappedGeneratedAssetNode._length);
        node = new GeneratedAssetNode(
          serializedNode[_FieldId.PhaseNumber.index] as int,
          _idToAssetId[serializedNode[_FieldId.PrimaryInput.index] as int],
          _deserializeBool(serializedNode[_FieldId.NeedsUpdate.index] as int),
          _deserializeBool(serializedNode[_FieldId.WasOutput.index] as int),
          id,
          globs: (serializedNode[_FieldId.Globs.index] as Iterable<String>)
              .map((pattern) => new Glob(pattern))
              .toSet(),
          lastKnownDigest: digest,
        );
        break;
    }
    node.outputs.addAll(_deserializeAssetIds(
        serializedNode[_FieldId.Outputs.index] as List<int>));
    node.primaryOutputs.addAll(_deserializeAssetIds(
        serializedNode[_FieldId.PrimaryOutputs.index] as List<int>));
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
      'version': _version,
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

/// Used to serialize the type of a node using an int.
enum _NodeTypeId { Source, Synthetic, Generated }

/// Field indexes for serialized nodes.
enum _FieldId {
  // First, the generic fields for all asset nodes.
  NodeType,
  Id,
  Outputs,
  PrimaryOutputs,
  // **Note**: You must update `_WrappedAssetNode._length` if another generic
  // field is added below `Digest`.
  Digest,

  // Fields below here are for generated nodes only.
  PrimaryInput,
  WasOutput,
  PhaseNumber,
  Globs,
  NeedsUpdate
}

/// Wraps an [AssetNode] in a class that implements [List] instead of
/// creating a new list for each one.
class _WrappedAssetNode extends Object with ListMixin implements List {
  final AssetNode node;
  final _AssetGraphSerializer serializer;

  _WrappedAssetNode(this.node, this.serializer);

  static final _length = _FieldId.Digest.index + 1;

  @override
  int get length => _length;

  @override
  set length(_) => throw new UnsupportedError(
      'length setter not unsupported for WrappedAssetNode');

  @override
  Object operator [](int index) {
    var fieldId = _FieldId.values[index];
    switch (fieldId) {
      case _FieldId.NodeType:
        if (node is SourceAssetNode) {
          return _NodeTypeId.Source.index;
        } else if (node is GeneratedAssetNode) {
          return _NodeTypeId.Generated.index;
        } else if (node is SyntheticAssetNode) {
          return _NodeTypeId.Synthetic.index;
        } else {
          throw new StateError('Unrecognized node type');
        }
        break;
      case _FieldId.Id:
        return serializer._assetIdToId[node.id];
      case _FieldId.Outputs:
        return node.outputs.map((id) => serializer._assetIdToId[id]).toList();
      case _FieldId.PrimaryOutputs:
        return node.primaryOutputs
            .map((id) => serializer._assetIdToId[id])
            .toList();
      case _FieldId.Digest:
        return node.lastKnownDigest == null
            ? null
            : BASE64.encode(node.lastKnownDigest.bytes);
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

  /// Offset in the serialized format for additional fields in this class but
  /// not in [_WrappedAssetNode].
  ///
  /// Indexes below this number are forwarded to `super[index]`.
  static final _serializedOffset = _WrappedAssetNode._length;

  static final _length = _FieldId.values.length;

  @override
  int get length => _length;

  _WrappedGeneratedAssetNode(
      this.generatedNode, _AssetGraphSerializer serializer)
      : super(generatedNode, serializer);

  @override
  Object operator [](int index) {
    if (index < _serializedOffset) return super[index];
    var fieldId = _FieldId.values[index];
    switch (fieldId) {
      case _FieldId.PrimaryInput:
        return generatedNode.primaryInput != null
            ? serializer._assetIdToId[generatedNode.primaryInput]
            : null;
      case _FieldId.WasOutput:
        return _serializeBool(generatedNode.wasOutput);
      case _FieldId.PhaseNumber:
        return generatedNode.phaseNumber;
      case _FieldId.Globs:
        return generatedNode.globs.map((glob) => glob.pattern).toList();
      case _FieldId.NeedsUpdate:
        return _serializeBool(generatedNode.needsUpdate);
      default:
        throw new RangeError.index(index, this);
    }
  }
}

int _serializeBool(bool value) => value ? 1 : 0;
