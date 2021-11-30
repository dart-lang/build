// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'graph.dart';

/// Part of the serialized graph, used to ensure versioning constraints.
///
/// This should be incremented any time the serialize/deserialize formats
/// change.
const _version = 24;

/// Deserializes an [AssetGraph] from a [Map].
class _AssetGraphDeserializer {
  // Iteration order does not matter
  final _idToAssetId = HashMap<int, AssetId>();
  final Map _serializedGraph;

  _AssetGraphDeserializer._(this._serializedGraph);

  factory _AssetGraphDeserializer(List<int> bytes) {
    dynamic decoded;
    try {
      decoded = jsonDecode(utf8.decode(bytes));
    } on FormatException {
      throw AssetGraphCorruptedException();
    }
    if (decoded is! Map) throw AssetGraphCorruptedException();
    if (decoded['version'] != _version) {
      throw AssetGraphCorruptedException();
    }
    return _AssetGraphDeserializer._(decoded);
  }

  /// Perform the deserialization, should only be called once.
  AssetGraph deserialize() {
    var packageLanguageVersions = {
      for (var entry in (_serializedGraph['packageLanguageVersions']
              as Map<String, dynamic>)
          .entries)
        entry.key: entry.value != null
            ? LanguageVersion.parse(entry.value as String)
            : null
    };
    var graph = AssetGraph._(
      _deserializeDigest(_serializedGraph['buildActionsDigest'] as String)!,
      _serializedGraph['dart_version'] as String,
      packageLanguageVersions,
      List.from(_serializedGraph['enabledExperiments'] as List),
    );

    var packageNames = _serializedGraph['packages'] as List;

    // Read in the id => AssetId map from the graph first.
    var assetPaths = _serializedGraph['assetPaths'] as List;
    for (var i = 0; i < assetPaths.length; i += 2) {
      var packageName = packageNames[assetPaths[i + 1] as int] as String;
      _idToAssetId[i ~/ 2] = AssetId(packageName, assetPaths[i] as String);
    }

    // Read in all the nodes and their outputs.
    //
    // Note that this does not read in the inputs of generated nodes.
    for (var serializedItem in _serializedGraph['nodes'] as Iterable) {
      graph._add(_deserializeAssetNode(serializedItem as List));
    }

    // Update the inputs of all generated nodes based on the outputs of the
    // current nodes.
    for (var node in graph.allNodes) {
      // These aren't explicitly added as inputs.
      if (node is BuilderOptionsAssetNode) continue;

      for (var output in node.outputs) {
        var inputsNode = graph.get(output) as NodeWithInputs?;
        if (inputsNode == null) {
          log.severe('Failed to locate $output referenced from ${node.id} '
              'which is a ${node.runtimeType}. If you encounter this error '
              'please copy the details from this message and add them to '
              'https://github.com/dart-lang/build/issues/1804.');
          throw AssetGraphCorruptedException();
        }
        inputsNode.inputs.add(node.id);
      }

      if (node is PostProcessAnchorNode) {
        graph.get(node.primaryInput)!.anchorOutputs.add(node.id);
      }
    }

    return graph;
  }

  AssetNode _deserializeAssetNode(List serializedNode) {
    AssetNode node;
    var typeId =
        _NodeType.values[serializedNode[_AssetField.nodeType.index] as int];
    var id = _idToAssetId[serializedNode[_AssetField.id.index] as int]!;
    var serializedDigest = serializedNode[_AssetField.digest.index] as String?;
    var digest = _deserializeDigest(serializedDigest);
    switch (typeId) {
      case _NodeType.source:
        assert(serializedNode.length == _WrappedAssetNode._length);
        node = SourceAssetNode(id, lastKnownDigest: digest);
        break;
      case _NodeType.syntheticSource:
        assert(serializedNode.length == _WrappedAssetNode._length);
        node = SyntheticSourceAssetNode(id);
        break;
      case _NodeType.generated:
        assert(serializedNode.length == _WrappedGeneratedAssetNode._length);
        var offset = _AssetField.values.length;
        node = GeneratedAssetNode(
          id,
          phaseNumber:
              serializedNode[_GeneratedField.phaseNumber.index + offset] as int,
          primaryInput: _idToAssetId[
              serializedNode[_GeneratedField.primaryInput.index + offset]
                  as int]!,
          state: NodeState.values[
              serializedNode[_GeneratedField.state.index + offset] as int],
          wasOutput: _deserializeBool(
              serializedNode[_GeneratedField.wasOutput.index + offset] as int),
          isFailure: _deserializeBool(
              serializedNode[_GeneratedField.isFailure.index + offset] as int),
          builderOptionsId: _idToAssetId[
              serializedNode[_GeneratedField.builderOptions.index + offset]
                  as int]!,
          lastKnownDigest: digest,
          previousInputsDigest: _deserializeDigest(serializedNode[
              _GeneratedField.previousInputsDigest.index + offset] as String?),
          isHidden: _deserializeBool(
              serializedNode[_GeneratedField.isHidden.index + offset] as int),
        );
        break;
      case _NodeType.glob:
        assert(serializedNode.length == _WrappedGlobAssetNode._length);
        var offset = _AssetField.values.length;
        node = GlobAssetNode(
          id,
          Glob(serializedNode[_GlobField.glob.index + offset] as String),
          serializedNode[_GlobField.phaseNumber.index + offset] as int,
          NodeState
              .values[serializedNode[_GlobField.state.index + offset] as int],
          lastKnownDigest: digest,
          results: _deserializeAssetIds(
                  serializedNode[_GlobField.results.index + offset] as List)
              .toList(),
        );
        break;
      case _NodeType.internal:
        assert(serializedNode.length == _WrappedAssetNode._length);
        node = InternalAssetNode(id, lastKnownDigest: digest);
        break;
      case _NodeType.builderOptions:
        assert(serializedNode.length == _WrappedAssetNode._length);
        node = BuilderOptionsAssetNode(id, digest!);
        break;
      case _NodeType.placeholder:
        assert(serializedNode.length == _WrappedAssetNode._length);
        node = PlaceHolderAssetNode(id);
        break;
      case _NodeType.postProcessAnchor:
        assert(serializedNode.length == _WrappedPostProcessAnchorNode._length);
        var offset = _AssetField.values.length;
        node = PostProcessAnchorNode(
            id,
            _idToAssetId[
                serializedNode[_PostAnchorField.primaryInput.index + offset]
                    as int]!,
            serializedNode[_PostAnchorField.actionNumber.index + offset] as int,
            _idToAssetId[
                serializedNode[_PostAnchorField.builderOptions.index + offset]
                    as int]!,
            previousInputsDigest: _deserializeDigest(serializedNode[
                    _PostAnchorField.previousInputsDigest.index + offset]
                as String?));
        break;
    }
    node.outputs.addAll(_deserializeAssetIds(
        serializedNode[_AssetField.outputs.index] as List));
    node.primaryOutputs.addAll(_deserializeAssetIds(
        serializedNode[_AssetField.primaryOutputs.index] as List));
    node.deletedBy.addAll(_deserializeAssetIds(
        (serializedNode[_AssetField.deletedBy.index] as List).cast<int>()));
    return node;
  }

  Iterable<AssetId> _deserializeAssetIds(List serializedIds) =>
      serializedIds.map((id) => _idToAssetId[id]!);

  bool _deserializeBool(int value) => value != 0;
}

/// Serializes an [AssetGraph] into a [Map].
class _AssetGraphSerializer {
  // Iteration order does not matter
  final _assetIdToId = HashMap<AssetId, int>();

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
      assetPaths
        ..add(node.id.path)
        ..add(packages.indexOf(node.id.package));
    }

    var result = <String, dynamic>{
      'version': _version,
      'dart_version': _graph.dartVersion,
      'nodes': _graph.allNodes.map(_serializeNode).toList(growable: false),
      'buildActionsDigest': _serializeDigest(_graph.buildPhasesDigest),
      'packages': packages,
      'assetPaths': assetPaths,
      'packageLanguageVersions': _graph.packageLanguageVersions
          .map((pkg, version) => MapEntry(pkg, version?.toString())),
      'enabledExperiments': _graph.enabledExperiments,
    };
    return utf8.encode(json.encode(result));
  }

  List _serializeNode(AssetNode node) {
    if (node is GeneratedAssetNode) {
      return _WrappedGeneratedAssetNode(node, this);
    } else if (node is PostProcessAnchorNode) {
      return _WrappedPostProcessAnchorNode(node, this);
    } else if (node is GlobAssetNode) {
      return _WrappedGlobAssetNode(node, this);
    } else {
      return _WrappedAssetNode(node, this);
    }
  }

  int findAssetIndex(AssetId id,
      {required AssetId from, required String field}) {
    final index = _assetIdToId[id];
    if (index == null) {
      log.severe('The $field field in $from references a non-existent asset '
          '$id and will corrupt the asset graph. '
          'If you encounter this error please copy '
          'the details from this message and add them to '
          'https://github.com/dart-lang/build/issues/1804.');
    }
    return index!;
  }
}

/// Used to serialize the type of a node using an int.
enum _NodeType {
  source,
  syntheticSource,
  generated,
  internal,
  builderOptions,
  placeholder,
  postProcessAnchor,
  glob,
}

/// Field indexes for all [AssetNode]s
enum _AssetField {
  nodeType,
  id,
  outputs,
  primaryOutputs,
  digest,
  deletedBy,
}

/// Field indexes for [GeneratedAssetNode]s
enum _GeneratedField {
  primaryInput,
  wasOutput,
  isFailure,
  phaseNumber,
  state,
  previousInputsDigest,
  builderOptions,
  isHidden,
}

/// Field indexes for [GlobAssetNode]s
enum _GlobField {
  phaseNumber,
  state,
  glob,
  results,
}

/// Field indexes for [PostProcessAnchorNode]s.
enum _PostAnchorField {
  actionNumber,
  builderOptions,
  previousInputsDigest,
  primaryInput,
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
  set length(void _) => throw UnsupportedError(
      'length setter not unsupported for WrappedAssetNode');

  @override
  Object? operator [](int index) {
    var fieldId = _AssetField.values[index];
    switch (fieldId) {
      case _AssetField.nodeType:
        if (node is SourceAssetNode) {
          return _NodeType.source.index;
        } else if (node is GeneratedAssetNode) {
          return _NodeType.generated.index;
        } else if (node is GlobAssetNode) {
          return _NodeType.glob.index;
        } else if (node is SyntheticSourceAssetNode) {
          return _NodeType.syntheticSource.index;
        } else if (node is InternalAssetNode) {
          return _NodeType.internal.index;
        } else if (node is BuilderOptionsAssetNode) {
          return _NodeType.builderOptions.index;
        } else if (node is PlaceHolderAssetNode) {
          return _NodeType.placeholder.index;
        } else if (node is PostProcessAnchorNode) {
          return _NodeType.postProcessAnchor.index;
        } else {
          throw StateError('Unrecognized node type');
        }
      case _AssetField.id:
        return serializer.findAssetIndex(node.id, from: node.id, field: 'id');
      case _AssetField.outputs:
        return node.outputs
            .map((id) =>
                serializer.findAssetIndex(id, from: node.id, field: 'outputs'))
            .toList(growable: false);
      case _AssetField.primaryOutputs:
        return node.primaryOutputs
            .map((id) => serializer.findAssetIndex(id,
                from: node.id, field: 'primaryOutputs'))
            .toList(growable: false);
      case _AssetField.digest:
        return _serializeDigest(node.lastKnownDigest);
      case _AssetField.deletedBy:
        return node.deletedBy
            .map((id) => serializer.findAssetIndex(id,
                from: node.id, field: 'deletedBy'))
            .toList(growable: false);
      default:
        throw RangeError.index(index, this);
    }
  }

  @override
  operator []=(void _, void __) =>
      throw UnsupportedError('[]= not supported for WrappedAssetNode');
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
  Object? operator [](int index) {
    if (index < _serializedOffset) return super[index];
    var fieldId = _GeneratedField.values[index - _serializedOffset];
    switch (fieldId) {
      case _GeneratedField.primaryInput:
        return serializer.findAssetIndex(generatedNode.primaryInput,
            from: generatedNode.id, field: 'primaryInput');
      case _GeneratedField.wasOutput:
        return _serializeBool(generatedNode.wasOutput);
      case _GeneratedField.isFailure:
        return _serializeBool(generatedNode.isFailure);
      case _GeneratedField.phaseNumber:
        return generatedNode.phaseNumber;
      case _GeneratedField.state:
        return generatedNode.state.index;
      case _GeneratedField.previousInputsDigest:
        return _serializeDigest(generatedNode.previousInputsDigest);
      case _GeneratedField.builderOptions:
        return serializer.findAssetIndex(generatedNode.builderOptionsId,
            from: generatedNode.id, field: 'builderOptions');
      case _GeneratedField.isHidden:
        return _serializeBool(generatedNode.isHidden);
      default:
        throw RangeError.index(index, this);
    }
  }
}

/// Wraps a [GlobAssetNode] in a class that implements [List] instead of
/// creating a new list for each one.
class _WrappedGlobAssetNode extends _WrappedAssetNode {
  final GlobAssetNode globNode;

  /// Offset in the serialized format for additional fields in this class but
  /// not in [_WrappedAssetNode].
  ///
  /// Indexes below this number are forwarded to `super[index]`.
  static final int _serializedOffset = _AssetField.values.length;

  static final int _length = _serializedOffset + _GlobField.values.length;

  @override
  int get length => _length;

  _WrappedGlobAssetNode(this.globNode, _AssetGraphSerializer serializer)
      : super(globNode, serializer);

  @override
  Object? operator [](int index) {
    if (index < _serializedOffset) return super[index];
    var fieldId = _GlobField.values[index - _serializedOffset];
    switch (fieldId) {
      case _GlobField.phaseNumber:
        return globNode.phaseNumber;
      case _GlobField.state:
        return globNode.state.index;
      case _GlobField.glob:
        return globNode.glob.pattern;
      case _GlobField.results:
        return globNode.results!
            .map((id) => serializer.findAssetIndex(id,
                from: globNode.id, field: 'results'))
            .toList(growable: false);
      default:
        throw RangeError.index(index, this);
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
  Object? operator [](int index) {
    if (index < _serializedOffset) return super[index];
    var fieldId = _PostAnchorField.values[index - _serializedOffset];
    switch (fieldId) {
      case _PostAnchorField.actionNumber:
        return wrappedNode.actionNumber;
      case _PostAnchorField.builderOptions:
        return serializer.findAssetIndex(wrappedNode.builderOptionsId,
            from: wrappedNode.id, field: 'builderOptions');
      case _PostAnchorField.previousInputsDigest:
        return _serializeDigest(wrappedNode.previousInputsDigest);
      case _PostAnchorField.primaryInput:
        return serializer.findAssetIndex(wrappedNode.primaryInput,
            from: wrappedNode.id, field: 'primaryInput');
      default:
        throw RangeError.index(index, this);
    }
  }
}

Digest? _deserializeDigest(String? serializedDigest) =>
    serializedDigest == null ? null : Digest(base64.decode(serializedDigest));

String? _serializeDigest(Digest? digest) =>
    digest == null ? null : base64.encode(digest.bytes);

int _serializeBool(bool value) => value ? 1 : 0;
