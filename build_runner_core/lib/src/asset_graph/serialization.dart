// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'graph.dart';

/// Part of the serialized graph, used to ensure versioning constraints.
///
/// This should be incremented any time the serialize/deserialize formats
/// change.
const _version = 26;

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
      packageLanguageVersions.build(),
      BuiltList<String>.from(_serializedGraph['enabledExperiments'] as List),
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

    return graph;
  }

  AssetNode _deserializeAssetNode(List serializedNode) =>
      serializers.deserializeWith(AssetNode.serializer, serializedNode)
          as AssetNode;
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
      'nodes': _graph.allNodes
          .map((node) => serializers.serializeWith(AssetNode.serializer, node))
          .toList(growable: false),
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

Digest? _deserializeDigest(String? serializedDigest) =>
    serializedDigest == null ? null : Digest(base64.decode(serializedDigest));

String? _serializeDigest(Digest? digest) =>
    digest == null ? null : base64.encode(digest.bytes);
