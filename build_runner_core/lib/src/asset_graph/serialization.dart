// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'graph.dart';

/// Part of the serialized graph, used to ensure versioning constraints.
///
/// This should be incremented any time the serialize/deserialize formats
/// change.
const _version = 30;

/// Deserializes an [AssetGraph] from a [Map].
AssetGraph deserializeAssetGraph(List<int> bytes) {
  dynamic serializedGraph;
  try {
    serializedGraph = jsonDecode(utf8.decode(bytes));
  } on FormatException {
    throw AssetGraphCorruptedException();
  }
  if (serializedGraph is! Map) throw AssetGraphCorruptedException();
  if (serializedGraph['version'] != _version) {
    throw AssetGraphCorruptedException();
  }

  identityAssetIdSerializer.deserializeWithObjects(
    (serializedGraph['ids'] as List).map(
      (id) => assetIdSerializer.deserialize(serializers, id as Object),
    ),
  );

  var packageLanguageVersions = {
    for (var entry
        in (serializedGraph['packageLanguageVersions'] as Map<String, dynamic>)
            .entries)
      entry.key:
          entry.value != null
              ? LanguageVersion.parse(entry.value as String)
              : null,
  };
  var graph = AssetGraph._fromSerialized(
    _deserializeDigest(serializedGraph['buildActionsDigest'] as String)!,
    serializers.deserialize(
          serializedGraph['inBuildPhasesOptionsDigests'],
          specifiedType: const FullType(BuiltList, [FullType(Digest)]),
        )
        as BuiltList<Digest>,
    serializers.deserialize(
          serializedGraph['postBuildActionsOptionsDigests'],
          specifiedType: const FullType(BuiltList, [FullType(Digest)]),
        )
        as BuiltList<Digest>,
    serializedGraph['dart_version'] as String,
    packageLanguageVersions.build(),
    BuiltList<String>.from(serializedGraph['enabledExperiments'] as List),
  );

  for (var serializedItem in serializedGraph['nodes'] as Iterable) {
    graph._add(_deserializeAssetNode(serializedItem as List));
  }

  final postProcessOutputs =
      serializers.deserialize(
            serializedGraph['postProcessOutputs'],
            specifiedType: postProcessBuildStepOutputsFullType,
          )
          as Map<String, Map<PostProcessBuildStepId, Set<AssetId>>>;

  for (final postProcessOutputsForPackage in postProcessOutputs.values) {
    for (final entry in postProcessOutputsForPackage.entries) {
      graph.updatePostProcessBuildStep(entry.key, outputs: entry.value);
    }
  }

  graph.previousPhasedAssetDeps = serializers.deserializeWith(
    PhasedAssetDeps.serializer,
    serializedGraph['phasedAssetDeps'],
  );

  identityAssetIdSerializer.reset();
  return graph;
}

AssetNode _deserializeAssetNode(List serializedNode) =>
    serializers.deserializeWith(AssetNode.serializer, serializedNode)
        as AssetNode;

/// Serializes an [AssetGraph] into a [Map].
List<int> serializeAssetGraph(AssetGraph graph) {
  // Serialize nodes first so all `AssetId` instances are seen by
  // `identityAssetIdSeralizer`.
  final nodes = graph.allNodes
      .map((node) => serializers.serializeWith(AssetNode.serializer, node))
      .toList(growable: false);
  final serializedPhasedAssetDeps = serializers.serializeWith(
    PhasedAssetDeps.serializer,
    graph.previousPhasedAssetDeps,
  );

  var result = <String, dynamic>{
    'version': _version,
    'ids': identityAssetIdSerializer.serializedObjects,
    'dart_version': graph.dartVersion,
    'nodes': nodes,
    'buildActionsDigest': _serializeDigest(graph.buildPhasesDigest),
    'packageLanguageVersions':
        graph.packageLanguageVersions
            .map((pkg, version) => MapEntry(pkg, version?.toString()))
            .toMap(),
    'enabledExperiments': graph.enabledExperiments.toList(),
    'postProcessOutputs': serializers.serialize(
      graph._postProcessBuildStepOutputs,
      specifiedType: postProcessBuildStepOutputsFullType,
    ),
    'inBuildPhasesOptionsDigests': serializers.serialize(
      graph.inBuildPhasesOptionsDigests,
      specifiedType: const FullType(BuiltList, [FullType(Digest)]),
    ),
    'postBuildActionsOptionsDigests': serializers.serialize(
      graph.postBuildActionsOptionsDigests,
      specifiedType: const FullType(BuiltList, [FullType(Digest)]),
    ),
    'phasedAssetDeps': serializedPhasedAssetDeps,
  };

  identityAssetIdSerializer.reset();
  return utf8.encode(json.encode(result));
}

Digest? _deserializeDigest(String? serializedDigest) =>
    serializedDigest == null ? null : Digest(base64.decode(serializedDigest));

String? _serializeDigest(Digest? digest) =>
    digest == null ? null : base64.encode(digest.bytes);
