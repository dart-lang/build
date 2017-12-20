// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'graph.dart';

/// Part of the serialized graph, used to ensure versioning constraints.
///
/// This should be incremented any time the serialize/deserialize formats
/// change.
const _version = 15;

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

    var graph = new AssetGraph._(
        _deserializeDigest(_serializedGraph['buildActionsDigest'] as String));

    // Read in the id => AssetId map from the graph first.
    for (var descriptor in _serializedGraph['serializedAssetIds']) {
      _idToAssetId[descriptor[0] as int] =
          new AssetId(descriptor[1] as String, descriptor[2] as String);
    }

    // Read in all the nodes and their outputs.
    //
    // Note that this does not read in the inputs of generated nodes.
    for (var serializedItem in _serializedGraph['nodes']) {
      graph._add(_deserializeAssetNode(serializedItem as List));
    }

    // Update the inputs of all generated nodes based on the outputs of the
    // current nodes.
    for (var node in graph.allNodes) {
      // These aren't explicitly added as inputs.
      if (node is BuilderOptionsAssetNode) continue;

      for (var output in node.outputs) {
        var generatedNode = graph.get(output) as GeneratedAssetNode;
        assert(generatedNode != null, 'Asset Graph is missing $output');
        generatedNode.inputs.add(node.id);
      }
    }

    return graph;
  }

  AssetNode _deserializeAssetNode(List serializedNode) {
    AssetNode node;
    var typeId = _NodeType.values[serializedNode[_Field.NodeType.index] as int];
    var id = _idToAssetId[serializedNode[_Field.Id.index] as int];
    var serializedDigest = serializedNode[_Field.Digest.index] as String;
    var digest = _deserializeDigest(serializedDigest);
    switch (typeId) {
      case _NodeType.Source:
        assert(serializedNode.length == _WrappedAssetNode._length);
        node = new SourceAssetNode(id, lastKnownDigest: digest);
        break;
      case _NodeType.SyntheticSource:
        assert(serializedNode.length == _WrappedAssetNode._length);
        node = new SyntheticSourceAssetNode(id);
        break;
      case _NodeType.Generated:
        assert(serializedNode.length == _WrappedGeneratedAssetNode._length);
        node = new GeneratedAssetNode(
          id,
          phaseNumber: serializedNode[_Field.PhaseNumber.index] as int,
          primaryInput:
              _idToAssetId[serializedNode[_Field.PrimaryInput.index] as int],
          needsUpdate:
              _deserializeBool(serializedNode[_Field.NeedsUpdate.index] as int),
          wasOutput:
              _deserializeBool(serializedNode[_Field.WasOutput.index] as int),
          builderOptionsId:
              _idToAssetId[serializedNode[_Field.BuilderOptions.index] as int],
          globs: (serializedNode[_Field.Globs.index] as Iterable<String>)
              .map((pattern) => new Glob(pattern))
              .toSet(),
          lastKnownDigest: digest,
          previousInputsDigest: _deserializeDigest(
              serializedNode[_Field.PreviousInputsDigest.index] as String),
          isHidden:
              _deserializeBool(serializedNode[_Field.IsHidden.index] as int),
        );
        break;
      case _NodeType.Internal:
        assert(serializedNode.length == _WrappedAssetNode._length);
        node = new InternalAssetNode(id, lastKnownDigest: digest);
        break;
      case _NodeType.BuilderOptions:
        assert(serializedNode.length == _WrappedAssetNode._length);
        node = new BuilderOptionsAssetNode(id, digest);
        break;
      case _NodeType.Placeholder:
        assert(serializedNode.length == _WrappedAssetNode._length);
        node = new PlaceHolderAssetNode(id);
        break;
    }
    node.outputs.addAll(_deserializeAssetIds(
        serializedNode[_Field.Outputs.index] as List<int>));
    node.primaryOutputs.addAll(_deserializeAssetIds(
        serializedNode[_Field.PrimaryOutputs.index] as List<int>));
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
      'buildActionsDigest': _serializeDigest(_graph.buildActionsDigest),
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
enum _NodeType {
  Source,
  SyntheticSource,
  Generated,
  Internal,
  BuilderOptions,
  Placeholder
}

/// Field indexes for serialized nodes.
enum _Field {
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
  NeedsUpdate,
  PreviousInputsDigest,
  BuilderOptions,
  IsHidden,
}

/// Wraps an [AssetNode] in a class that implements [List] instead of
/// creating a new list for each one.
class _WrappedAssetNode extends Object with ListMixin implements List {
  final AssetNode node;
  final _AssetGraphSerializer serializer;

  _WrappedAssetNode(this.node, this.serializer);

  static final int _length = _Field.Digest.index + 1;

  @override
  int get length => _length;

  @override
  set length(_) => throw new UnsupportedError(
      'length setter not unsupported for WrappedAssetNode');

  @override
  Object operator [](int index) {
    var fieldId = _Field.values[index];
    switch (fieldId) {
      case _Field.NodeType:
        if (node is SourceAssetNode) {
          return _NodeType.Source.index;
        } else if (node is GeneratedAssetNode) {
          return _NodeType.Generated.index;
        } else if (node is SyntheticSourceAssetNode) {
          return _NodeType.SyntheticSource.index;
        } else if (node is InternalAssetNode) {
          return _NodeType.Internal.index;
        } else if (node is BuilderOptionsAssetNode) {
          return _NodeType.BuilderOptions.index;
        } else if (node is PlaceHolderAssetNode) {
          return _NodeType.Placeholder.index;
        } else {
          throw new StateError('Unrecognized node type');
        }
        break;
      case _Field.Id:
        return serializer._assetIdToId[node.id];
      case _Field.Outputs:
        return node.outputs.map((id) => serializer._assetIdToId[id]).toList();
      case _Field.PrimaryOutputs:
        return node.primaryOutputs
            .map((id) => serializer._assetIdToId[id])
            .toList();
      case _Field.Digest:
        return _serializeDigest(node.lastKnownDigest);
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
  static final int _serializedOffset = _WrappedAssetNode._length;

  static final int _length = _Field.values.length;

  @override
  int get length => _length;

  _WrappedGeneratedAssetNode(
      this.generatedNode, _AssetGraphSerializer serializer)
      : super(generatedNode, serializer);

  @override
  Object operator [](int index) {
    if (index < _serializedOffset) return super[index];
    var fieldId = _Field.values[index];
    switch (fieldId) {
      case _Field.PrimaryInput:
        return generatedNode.primaryInput != null
            ? serializer._assetIdToId[generatedNode.primaryInput]
            : null;
      case _Field.WasOutput:
        return _serializeBool(generatedNode.wasOutput);
      case _Field.PhaseNumber:
        return generatedNode.phaseNumber;
      case _Field.Globs:
        return generatedNode.globs.map((glob) => glob.pattern).toList();
      case _Field.NeedsUpdate:
        return _serializeBool(generatedNode.needsUpdate);
      case _Field.PreviousInputsDigest:
        return _serializeDigest(generatedNode.previousInputsDigest);
      case _Field.BuilderOptions:
        return serializer._assetIdToId[generatedNode.builderOptionsId];
      case _Field.IsHidden:
        return _serializeBool(generatedNode.isHidden);
      default:
        throw new RangeError.index(index, this);
    }
  }
}

Digest _deserializeDigest(String serializedDigest) => serializedDigest == null
    ? null
    : new Digest(BASE64.decode(serializedDigest));

String _serializeDigest(Digest digest) =>
    digest == null ? null : BASE64.encode(digest.bytes);

int _serializeBool(bool value) => value ? 1 : 0;
