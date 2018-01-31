// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'graph.dart';

/// Part of the serialized graph, used to ensure versioning constraints.
///
/// This should be incremented any time the serialize/deserialize formats
/// change.
const _version = 17;

/// Deserializes an [AssetGraph] from a [Map].
class _AssetGraphDeserializer {
  // Iteration order does not matter
  final _idToAssetId = new HashMap<int, AssetId>();
  final Map _serializedGraph;

  _AssetGraphDeserializer(List<int> bytes)
      : _serializedGraph = JSON.decode(UTF8.decode(bytes)) as Map;

  /// Perform the deserialization, should only be called once.
  AssetGraph deserialize() {
    if (_serializedGraph['version'] != _version) {
      throw new AssetGraphVersionException(
          _serializedGraph['version'] as int, _version);
    }

    var graph = new AssetGraph._(
        _deserializeDigest(_serializedGraph['buildActionsDigest'] as String));

    var packageNames = _serializedGraph['packages'] as List<String>;

    // Read in the id => AssetId map from the graph first.
    var assetPaths = _serializedGraph['assetPaths'] as List;
    for (var i = 0; i < assetPaths.length; i += 2) {
      var packageName = packageNames[assetPaths[i + 1] as int];
      _idToAssetId[i ~/ 2] = new AssetId(packageName, assetPaths[i] as String);
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

    // Read all the currently failing actions.
    var serializedFailedActions = _serializedGraph['failedActions'] as List;
    for (int i = 0; i < serializedFailedActions.length; i += 2) {
      var phase = serializedFailedActions[i] as int;
      var serializedIds = serializedFailedActions[i + 1] as List<int>;
      graph._failedActions[phase] = serializedIds
          .map((serializedId) => _idToAssetId[serializedId])
          .toSet();
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

  Iterable<AssetId> _deserializeAssetIds(List<int> serializedIds) =>
      serializedIds.map((id) => _idToAssetId[id]);

  bool _deserializeBool(int value) => value == 0 ? false : true;
}

/// Serializes an [AssetGraph] into a [Map].
class _AssetGraphSerializer {
  // Iteration order does not matter
  final _assetIdToId = new HashMap<AssetId, int>();

  final AssetGraph _graph;

  _AssetGraphSerializer(this._graph);

  /// Perform the serialization, should only be called once.
  List<int> serialize() {
    var pathId = 0;
    // [path0, packageId0, path1, packageId1, ...]
    var assetPaths = <dynamic>[];
    var packages = _graph._nodesByPackage.keys.toList(growable: false);
    for (var node in _graph.allNodes) {
      _assetIdToId[node.id] = pathId;
      pathId++;
      assetPaths.add(node.id.path);
      assetPaths.add(packages.indexOf(node.id.package));
    }

    var result = <String, dynamic>{
      'version': _version,
      'nodes': _graph.allNodes.map(_serializeNode).toList(growable: false),
      'buildActionsDigest': _serializeDigest(_graph.buildActionsDigest),
      'packages': packages,
      'assetPaths': assetPaths,
      'failedActions': _serializeFailedActions(_graph.failedActions),
    };
    return UTF8.encode(JSON.encode(result));
  }

  List _serializeNode(AssetNode node) {
    if (node is GeneratedAssetNode) {
      return new _WrappedGeneratedAssetNode(node, this);
    } else {
      return new _WrappedAssetNode(node, this);
    }
  }

  List _serializeFailedActions(Map<int, Iterable<AssetId>> failedActions) {
    var serialized = <dynamic>[];
    failedActions.forEach((phaseNum, assetIds) {
      serialized
        ..add(phaseNum)
        ..add(assetIds.map((id) => _assetIdToId[id]).toList(growable: false));
    });
    return serialized;
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
        return node.outputs
            .map((id) => serializer._assetIdToId[id])
            .toList(growable: false);
      case _Field.PrimaryOutputs:
        return node.primaryOutputs
            .map((id) => serializer._assetIdToId[id])
            .toList(growable: false);
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
        return generatedNode.globs
            .map((glob) => glob.pattern)
            .toList(growable: false);
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
