// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'graph.dart';

/// Part of the serialized graph, used to ensure versioning constraints.
///
/// This should be incremented any time the serialize/deserialize formats
/// change.
const _version = 20;

/// Deserializes an [AssetGraph] from a [Map].
class _AssetGraphDeserializer {
  // Iteration order does not matter
  final _idToAssetId = new HashMap<int, AssetId>();
  final Map _serializedGraph;

  _AssetGraphDeserializer(List<int> bytes)
      : _serializedGraph = json.decode(utf8.decode(bytes)) as Map;

  /// Perform the deserialization, should only be called once.
  AssetGraph deserialize() {
    if (_serializedGraph['version'] != _version) {
      throw new AssetGraphVersionException(
          _serializedGraph['version'] as int, _version);
    }

    var graph = new AssetGraph._(
        _deserializeDigest(_serializedGraph['buildActionsDigest'] as String),
        _serializedGraph['dart_version'] as String);

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

      if (node is PostProcessAnchorNode) {
        graph.get(node.primaryInput).anchorOutputs.add(node.id);
      }
    }

    return graph;
  }

  AssetNode _deserializeAssetNode(List serializedNode) {
    AssetNode node;
    var typeId =
        _NodeType.values[serializedNode[_AssetField.NodeType.index] as int];
    var id = _idToAssetId[serializedNode[_AssetField.Id.index] as int];
    var serializedDigest = serializedNode[_AssetField.Digest.index] as String;
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
        var offset = _AssetField.values.length;
        node = new GeneratedAssetNode(
          id,
          phaseNumber:
              serializedNode[_GeneratedField.PhaseNumber.index + offset] as int,
          primaryInput: _idToAssetId[
              serializedNode[_GeneratedField.PrimaryInput.index + offset]
                  as int],
          state: GeneratedNodeState.values[
              serializedNode[_GeneratedField.State.index + offset] as int],
          wasOutput: _deserializeBool(
              serializedNode[_GeneratedField.WasOutput.index + offset] as int),
          isFailure: _deserializeBool(
              serializedNode[_GeneratedField.IsFailure.index + offset] as int),
          builderOptionsId: _idToAssetId[
              serializedNode[_GeneratedField.BuilderOptions.index + offset]
                  as int],
          globs: (serializedNode[_GeneratedField.Globs.index + offset]
                  as Iterable<String>)
              .map((pattern) => new Glob(pattern))
              .toSet(),
          lastKnownDigest: digest,
          previousInputsDigest: _deserializeDigest(serializedNode[
              _GeneratedField.PreviousInputsDigest.index + offset] as String),
          isHidden: _deserializeBool(
              serializedNode[_GeneratedField.IsHidden.index + offset] as int),
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
      case _NodeType.PostProcessAnchor:
        assert(serializedNode.length == _WrappedPostProcessAnchorNode._length);
        var offset = _AssetField.values.length;
        node = new PostProcessAnchorNode(
            id,
            _idToAssetId[
                serializedNode[_PostAnchorField.PrimaryInput.index + offset]
                    as int],
            serializedNode[_PostAnchorField.ActionNumber.index + offset] as int,
            _idToAssetId[
                serializedNode[_PostAnchorField.BuilderOptions.index + offset]
                    as int],
            previousInputsDigest: _deserializeDigest(serializedNode[
                    _PostAnchorField.PreviousInputsDigest.index + offset]
                as String));
    }
    node.outputs.addAll(_deserializeAssetIds(
        serializedNode[_AssetField.Outputs.index] as List<int>));
    node.primaryOutputs.addAll(_deserializeAssetIds(
        serializedNode[_AssetField.PrimaryOutputs.index] as List<int>));
    node.isDeleted =
        _deserializeBool(serializedNode[_AssetField.IsDeleted.index] as int);
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
      'dart_version': _graph.dartVersion,
      'nodes': _graph.allNodes.map(_serializeNode).toList(growable: false),
      'buildActionsDigest': _serializeDigest(_graph.buildPhasesDigest),
      'packages': packages,
      'assetPaths': assetPaths,
    };
    return utf8.encode(json.encode(result));
  }

  List _serializeNode(AssetNode node) {
    if (node is GeneratedAssetNode) {
      return new _WrappedGeneratedAssetNode(node, this);
    } else if (node is PostProcessAnchorNode) {
      return new _WrappedPostProcessAnchorNode(node, this);
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
  Placeholder,
  PostProcessAnchor,
}

/// Field indexes for all [AssetNode]s
enum _AssetField {
  NodeType,
  Id,
  Outputs,
  PrimaryOutputs,
  Digest,
  IsDeleted,
}

/// Field indexes for [GeneratedAssetNode]s
enum _GeneratedField {
  PrimaryInput,
  WasOutput,
  IsFailure,
  PhaseNumber,
  Globs,
  State,
  PreviousInputsDigest,
  BuilderOptions,
  IsHidden,
}

/// Field indexes for [PostProcessAnchorNode]s.
enum _PostAnchorField {
  ActionNumber,
  BuilderOptions,
  PreviousInputsDigest,
  PrimaryInput,
}

/// Wraps an [AssetNode] in a class that implements [List] instead of
/// creating a new list for each one.
class _WrappedAssetNode extends Object with ListMixin implements List {
  final AssetNode node;
  final _AssetGraphSerializer serializer;

  _WrappedAssetNode(this.node, this.serializer);

  static final int _length = _AssetField.values.length;

  @override
  int get length => _length;

  @override
  set length(_) => throw new UnsupportedError(
      'length setter not unsupported for WrappedAssetNode');

  @override
  Object operator [](int index) {
    var fieldId = _AssetField.values[index];
    switch (fieldId) {
      case _AssetField.NodeType:
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
        } else if (node is PostProcessAnchorNode) {
          return _NodeType.PostProcessAnchor.index;
        } else {
          throw new StateError('Unrecognized node type');
        }
        break;
      case _AssetField.Id:
        return serializer._assetIdToId[node.id];
      case _AssetField.Outputs:
        return node.outputs
            .map((id) => serializer._assetIdToId[id])
            .toList(growable: false);
      case _AssetField.PrimaryOutputs:
        return node.primaryOutputs
            .map((id) => serializer._assetIdToId[id])
            .toList(growable: false);
      case _AssetField.Digest:
        return _serializeDigest(node.lastKnownDigest);
      case _AssetField.IsDeleted:
        return _serializeBool(node.isDeleted);
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
  static final int _serializedOffset = _AssetField.values.length;

  static final int _length = _serializedOffset + _GeneratedField.values.length;

  @override
  int get length => _length;

  _WrappedGeneratedAssetNode(
      this.generatedNode, _AssetGraphSerializer serializer)
      : super(generatedNode, serializer);

  @override
  Object operator [](int index) {
    if (index < _serializedOffset) return super[index];
    var fieldId = _GeneratedField.values[index - _serializedOffset];
    switch (fieldId) {
      case _GeneratedField.PrimaryInput:
        return generatedNode.primaryInput != null
            ? serializer._assetIdToId[generatedNode.primaryInput]
            : null;
      case _GeneratedField.WasOutput:
        return _serializeBool(generatedNode.wasOutput);
      case _GeneratedField.IsFailure:
        return _serializeBool(generatedNode.isFailure);
      case _GeneratedField.PhaseNumber:
        return generatedNode.phaseNumber;
      case _GeneratedField.Globs:
        return generatedNode.globs
            .map((glob) => glob.pattern)
            .toList(growable: false);
      case _GeneratedField.State:
        return generatedNode.state.index;
      case _GeneratedField.PreviousInputsDigest:
        return _serializeDigest(generatedNode.previousInputsDigest);
      case _GeneratedField.BuilderOptions:
        return serializer._assetIdToId[generatedNode.builderOptionsId];
      case _GeneratedField.IsHidden:
        return _serializeBool(generatedNode.isHidden);
      default:
        throw new RangeError.index(index, this);
    }
  }
}

/// Wraps a [PostProcessAnchorNode] in a class that implements [List] instead of
/// creating a new list for each one.
class _WrappedPostProcessAnchorNode extends _WrappedAssetNode {
  final PostProcessAnchorNode wrappedNode;

  /// Offset in the serialized format for additional fields in this class but
  /// not in [_WrappedAssetNode].
  ///
  /// Indexes below this number are forwarded to `super[index]`.
  static final int _serializedOffset = _AssetField.values.length;

  static final int _length = _serializedOffset + _PostAnchorField.values.length;

  @override
  int get length => _length;

  _WrappedPostProcessAnchorNode(
      this.wrappedNode, _AssetGraphSerializer serializer)
      : super(wrappedNode, serializer);

  @override
  Object operator [](int index) {
    if (index < _serializedOffset) return super[index];
    var fieldId = _PostAnchorField.values[index - _serializedOffset];
    switch (fieldId) {
      case _PostAnchorField.ActionNumber:
        return wrappedNode.actionNumber;
      case _PostAnchorField.BuilderOptions:
        return serializer._assetIdToId[wrappedNode.builderOptionsId];
      case _PostAnchorField.PreviousInputsDigest:
        return _serializeDigest(wrappedNode.previousInputsDigest);
      case _PostAnchorField.PrimaryInput:
        return wrappedNode.primaryInput != null
            ? serializer._assetIdToId[wrappedNode.primaryInput]
            : null;
      default:
        throw new RangeError.index(index, this);
    }
  }
}

Digest _deserializeDigest(String serializedDigest) => serializedDigest == null
    ? null
    : new Digest(base64.decode(serializedDigest));

String _serializeDigest(Digest digest) =>
    digest == null ? null : base64.encode(digest.bytes);

int _serializeBool(bool value) => value ? 1 : 0;
