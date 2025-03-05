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
      for (var entry
          in (_serializedGraph['packageLanguageVersions']
                  as Map<String, dynamic>)
              .entries)
        entry.key:
            entry.value != null
                ? LanguageVersion.parse(entry.value as String)
                : null,
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
      if (node.type == NodeType.builderOptions) continue;

      for (var output in node.outputs) {
        var inputsNode = graph.get(output);
        if (inputsNode == null ||
            (inputsNode.type != NodeType.generated &&
                inputsNode.type != NodeType.glob)) {
          log.severe(
            'Failed to locate $output referenced from ${node.id} '
            'which is a ${node.runtimeType}. If you encounter this error '
            'please copy the details from this message and add them to '
            'https://github.com/dart-lang/build/issues/1804.',
          );
          throw AssetGraphCorruptedException();
        }
        if (inputsNode.type == NodeType.generated) {
          inputsNode.generatedNodeState.inputs.add(node.id);
        } else {
          inputsNode.globNodeState.inputs.add(node.id);
        }
      }

      if (node.type == NodeType.postProcessAnchor) {
        graph
            .get(node.postProcessAnchorNodeConfiguration.primaryInput)!
            .mutate
            .anchorOutputs
            .add(node.id);
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
        node = AssetNode.source(id, lastKnownDigest: digest);
        break;
      case _NodeType.syntheticSource:
        assert(serializedNode.length == _WrappedAssetNode._length);
        node = AssetNode.missingSource(id);
        break;
      case _NodeType.generated:
        assert(serializedNode.length == _WrappedGeneratedAssetNode._length);
        var offset = _AssetField.values.length;
        node = AssetNode.generated(
          id,
          phaseNumber:
              serializedNode[_GeneratedField.phaseNumber.index + offset] as int,
          primaryInput:
              _idToAssetId[serializedNode[_GeneratedField.primaryInput.index +
                      offset]
                  as int]!,
          state:
              PendingBuildAction
                  .values[serializedNode[_GeneratedField.state.index + offset]
                  as int],
          wasOutput: _deserializeBool(
            serializedNode[_GeneratedField.wasOutput.index + offset] as int,
          ),
          isFailure: _deserializeBool(
            serializedNode[_GeneratedField.isFailure.index + offset] as int,
          ),
          builderOptionsId:
              _idToAssetId[serializedNode[_GeneratedField.builderOptions.index +
                      offset]
                  as int]!,
          lastKnownDigest: digest,
          previousInputsDigest: _deserializeDigest(
            serializedNode[_GeneratedField.previousInputsDigest.index + offset]
                as String?,
          ),
          isHidden: _deserializeBool(
            serializedNode[_GeneratedField.isHidden.index + offset] as int,
          ),
        );
        break;
      case _NodeType.glob:
        assert(serializedNode.length == _WrappedGlobAssetNode._length);
        var offset = _AssetField.values.length;
        node = AssetNode.glob(
          id,
          glob: Glob(serializedNode[_GlobField.glob.index + offset] as String),
          phaseNumber:
              serializedNode[_GlobField.phaseNumber.index + offset] as int,
          pendingBuildAction:
              PendingBuildAction.values[serializedNode[_GlobField.state.index +
                      offset]
                  as int],
          lastKnownDigest: digest,
          results:
              _deserializeAssetIds(
                serializedNode[_GlobField.results.index + offset] as List,
              ).toList(),
        );
        break;
      case _NodeType.internal:
        assert(serializedNode.length == _WrappedAssetNode._length);
        node = AssetNode.internal(id, lastKnownDigest: digest);
        break;
      case _NodeType.builderOptions:
        assert(serializedNode.length == _WrappedAssetNode._length);
        node = AssetNode.builderOptions(id, lastKnownDigest: digest!);
        break;
      case _NodeType.placeholder:
        assert(serializedNode.length == _WrappedAssetNode._length);
        node = AssetNode.placeholder(id);
        break;
      case _NodeType.postProcessAnchor:
        assert(serializedNode.length == _WrappedPostProcessAnchorNode._length);
        var offset = _AssetField.values.length;
        node = AssetNode.postProcessAnchor(
          id,
          primaryInput:
              _idToAssetId[serializedNode[_PostAnchorField.primaryInput.index +
                      offset]
                  as int]!,
          actionNumber:
              serializedNode[_PostAnchorField.actionNumber.index + offset]
                  as int,
          builderOptionsId:
              _idToAssetId[serializedNode[_PostAnchorField
                          .builderOptions
                          .index +
                      offset]
                  as int]!,
          previousInputsDigest: _deserializeDigest(
            serializedNode[_PostAnchorField.previousInputsDigest.index + offset]
                as String?,
          ),
        );
        break;
    }
    node.mutate.outputs.addAll(
      _deserializeAssetIds(serializedNode[_AssetField.outputs.index] as List),
    );
    node.mutate.primaryOutputs.addAll(
      _deserializeAssetIds(
        serializedNode[_AssetField.primaryOutputs.index] as List,
      ),
    );
    node.mutate.deletedBy.addAll(
      _deserializeAssetIds(
        (serializedNode[_AssetField.deletedBy.index] as List).cast<int>(),
      ),
    );
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
      'packageLanguageVersions': _graph.packageLanguageVersions.map(
        (pkg, version) => MapEntry(pkg, version?.toString()),
      ),
      'enabledExperiments': _graph.enabledExperiments,
    };
    return utf8.encode(json.encode(result));
  }

  List _serializeNode(AssetNode node) {
    if (node.type == NodeType.generated) {
      return _WrappedGeneratedAssetNode(node, this);
    } else if (node.type == NodeType.postProcessAnchor) {
      return _WrappedPostProcessAnchorNode(node, this);
    } else if (node.type == NodeType.glob) {
      return _WrappedGlobAssetNode(node, this);
    } else {
      return _WrappedAssetNode(node, this);
    }
  }

  int findAssetIndex(
    AssetId id, {
    required AssetId from,
    required String field,
  }) {
    final index = _assetIdToId[id];
    if (index == null) {
      log.severe(
        'The $field field in $from references a non-existent asset '
        '$id and will corrupt the asset graph. '
        'If you encounter this error please copy '
        'the details from this message and add them to '
        'https://github.com/dart-lang/build/issues/1804.',
      );
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
enum _AssetField { nodeType, id, outputs, primaryOutputs, digest, deletedBy }

/// Field indexes for [AssetNode.generated]s
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

/// Field indexes for [AssetNode.glob]s
enum _GlobField { phaseNumber, state, glob, results }

/// Field indexes for [AssetNode.postProcessAnchor]s.
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
  set length(void _) =>
      throw UnsupportedError(
        'length setter not unsupported for WrappedAssetNode',
      );

  @override
  Object? operator [](int index) {
    var fieldId = _AssetField.values[index];
    switch (fieldId) {
      case _AssetField.nodeType:
        switch (node.type) {
          case NodeType.source:
            return _NodeType.source.index;
          case NodeType.generated:
            return _NodeType.generated.index;
          case NodeType.glob:
            return _NodeType.glob.index;
          case NodeType.syntheticSource:
            return _NodeType.syntheticSource.index;
          case NodeType.internal:
            return _NodeType.internal.index;
          case NodeType.builderOptions:
            return _NodeType.builderOptions.index;

          case NodeType.placeholder:
            return _NodeType.placeholder.index;
          case NodeType.postProcessAnchor:
            return _NodeType.postProcessAnchor.index;
        }
      case _AssetField.id:
        return serializer.findAssetIndex(node.id, from: node.id, field: 'id');
      case _AssetField.outputs:
        return node.outputs
            .map(
              (id) => serializer.findAssetIndex(
                id,
                from: node.id,
                field: 'outputs',
              ),
            )
            .toList(growable: false);
      case _AssetField.primaryOutputs:
        return node.primaryOutputs
            .map(
              (id) => serializer.findAssetIndex(
                id,
                from: node.id,
                field: 'primaryOutputs',
              ),
            )
            .toList(growable: false);
      case _AssetField.digest:
        return _serializeDigest(node.lastKnownDigest);
      case _AssetField.deletedBy:
        return node.deletedBy
            .map(
              (id) => serializer.findAssetIndex(
                id,
                from: node.id,
                field: 'deletedBy',
              ),
            )
            .toList(growable: false);
    }
  }

  @override
  void operator []=(void _, void _) =>
      throw UnsupportedError('[]= not supported for WrappedAssetNode');
}

/// Wraps an [AssetNode.generated] in a class that implements [List] instead of
/// creating a new list for each one.
class _WrappedGeneratedAssetNode extends _WrappedAssetNode {
  final AssetNode generatedNode;

  /// Offset in the serialized format for additional fields in this class but
  /// not in [_WrappedAssetNode].
  ///
  /// Indexes below this number are forwarded to `super[index]`.
  static final int _serializedOffset = _AssetField.values.length;

  static final int _length = _serializedOffset + _GeneratedField.values.length;

  @override
  int get length => _length;

  _WrappedGeneratedAssetNode(
    this.generatedNode,
    _AssetGraphSerializer serializer,
  ) : super(generatedNode, serializer);

  @override
  Object? operator [](int index) {
    if (index < _serializedOffset) return super[index];
    var fieldId = _GeneratedField.values[index - _serializedOffset];
    final configuration = generatedNode.generatedNodeConfiguration;
    final state = generatedNode.generatedNodeState;
    return switch (fieldId) {
      _GeneratedField.primaryInput => serializer.findAssetIndex(
        configuration.primaryInput,
        from: generatedNode.id,
        field: 'primaryInput',
      ),
      _GeneratedField.wasOutput => _serializeBool(state.wasOutput),
      _GeneratedField.isFailure => _serializeBool(state.isFailure),
      _GeneratedField.phaseNumber => configuration.phaseNumber,
      _GeneratedField.state => state.pendingBuildAction.index,
      _GeneratedField.previousInputsDigest => _serializeDigest(
        state.previousInputsDigest,
      ),
      _GeneratedField.builderOptions => serializer.findAssetIndex(
        configuration.builderOptionsId,
        from: generatedNode.id,
        field: 'builderOptions',
      ),
      _GeneratedField.isHidden => _serializeBool(configuration.isHidden),
    };
  }
}

/// Wraps an [AssetNode.glob] in a class that implements [List] instead of
/// creating a new list for each one.
class _WrappedGlobAssetNode extends _WrappedAssetNode {
  final AssetNode globNode;

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
    final configuration = globNode.globNodeConfiguration;
    final state = globNode.globNodeState;
    return switch (fieldId) {
      _GlobField.phaseNumber => configuration.phaseNumber,
      _GlobField.state => state.pendingBuildAction.index,
      _GlobField.glob => configuration.glob.pattern,
      _GlobField.results => state.results!
          .map(
            (id) => serializer.findAssetIndex(
              id,
              from: globNode.id,
              field: 'results',
            ),
          )
          .toList(growable: false),
    };
  }
}

/// Wraps a [AssetNode.postProcessAnchor] in a class that implements [List]
/// instead of creating a new list for each one.
class _WrappedPostProcessAnchorNode extends _WrappedAssetNode {
  final AssetNode wrappedNode;

  /// Offset in the serialized format for additional fields in this class but
  /// not in [_WrappedAssetNode].
  ///
  /// Indexes below this number are forwarded to `super[index]`.
  static final int _serializedOffset = _AssetField.values.length;

  static final int _length = _serializedOffset + _PostAnchorField.values.length;

  @override
  int get length => _length;

  _WrappedPostProcessAnchorNode(
    this.wrappedNode,
    _AssetGraphSerializer serializer,
  ) : super(wrappedNode, serializer);

  @override
  Object? operator [](int index) {
    if (index < _serializedOffset) return super[index];
    var fieldId = _PostAnchorField.values[index - _serializedOffset];
    final nodeConfiguration = wrappedNode.postProcessAnchorNodeConfiguration;
    final nodeState = wrappedNode.postProcessAnchorNodeState;
    return switch (fieldId) {
      _PostAnchorField.actionNumber => nodeConfiguration.actionNumber,
      _PostAnchorField.builderOptions => serializer.findAssetIndex(
        nodeConfiguration.builderOptionsId,
        from: wrappedNode.id,
        field: 'builderOptions',
      ),
      _PostAnchorField.previousInputsDigest => _serializeDigest(
        nodeState.previousInputsDigest,
      ),
      _PostAnchorField.primaryInput => serializer.findAssetIndex(
        nodeConfiguration.primaryInput,
        from: wrappedNode.id,
        field: 'primaryInput',
      ),
    };
  }
}

Digest? _deserializeDigest(String? serializedDigest) =>
    serializedDigest == null ? null : Digest(base64.decode(serializedDigest));

String? _serializeDigest(Digest? digest) =>
    digest == null ? null : base64.encode(digest.bytes);

int _serializeBool(bool value) => value ? 1 : 0;
