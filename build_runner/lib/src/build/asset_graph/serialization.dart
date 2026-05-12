// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'graph.dart';

/// Part of the serialized graph, used to ensure versioning constraints.
///
/// This should be incremented any time the serialize/deserialize formats
/// change.

/// Deserializes an [AssetGraph] from a [Map].
///
/// Returns `null` if deserialization fails.
AssetGraph? deserializeAssetGraph(Map serializedGraph) {
  identityAssetIdSerializer.deserializeWithObjects(
    (serializedGraph['ids'] as List).map(
      (id) => assetIdSerializer.deserialize(serializers, id as Object),
    ),
  );

  final graph = AssetGraph();

  for (final serializedItem in serializedGraph['nodes'] as Iterable) {
    graph._nodes.add(_deserializeAssetNode(serializedItem as List));
  }

  final postProcessResults =
      serializers.deserialize(
            serializedGraph['postProcessResults'],
            specifiedType: postProcessBuildStepResultsFullType,
          )
          as Map<
            String,
            Map<PostProcessBuildStepId, PostProcessBuildStepResult>
          >;

  for (final postProcessResultsForPackage in postProcessResults.values) {
    for (final entry in postProcessResultsForPackage.entries) {
      graph.updatePostProcessBuildStepResult(entry.key, entry.value);
    }
  }

  graph.previousPhasedAssetDeps = serializers.deserializeWith(
    PhasedAssetDeps.serializer,
    serializedGraph['phasedAssetDeps'],
  );

  if (serializedGraph.containsKey('buildStepResults')) {
    final deserializedResults =
        serializers.deserialize(
              serializedGraph['buildStepResults'],
              specifiedType: const FullType(BuiltMap, [
                FullType(BuildStepId),
                FullType(BuildStepResult),
              ]),
            )
            as BuiltMap<BuildStepId, BuildStepResult>;
    for (final entry in deserializedResults.entries) {
      graph.updateBuildStepResult(entry.key, entry.value);
    }
  }

  if (serializedGraph.containsKey('globResults')) {
    final deserializedResults =
        serializers.deserialize(
              serializedGraph['globResults'],
              specifiedType: const FullType(BuiltMap, [
                FullType(GlobId),
                FullType(GlobResult),
              ]),
            )
            as BuiltMap<GlobId, GlobResult>;
    for (final entry in deserializedResults.entries) {
      graph.updateGlobResult(entry.key, entry.value);
    }
  }

  identityAssetIdSerializer.reset();
  return graph;
}

AssetNode _deserializeAssetNode(List serializedNode) =>
    serializers.deserializeWith(AssetNode.serializer, serializedNode)
        as AssetNode;

/// Serializes an [AssetGraph] into a [Map].
Map<String, Object?> serializeAssetGraph(AssetGraph graph) {
  // Serialize nodes first so all `AssetId` instances are seen by
  // `identityAssetIdSeralizer`.
  final nodes = graph.allNodes
      .map((node) => serializers.serializeWith(AssetNode.serializer, node))
      .toList(growable: false);
  final serializedPhasedAssetDeps = serializers.serializeWith(
    PhasedAssetDeps.serializer,
    graph.previousPhasedAssetDeps,
  );

  final result = <String, Object?>{
    'ids': identityAssetIdSerializer.serializedObjects,
    'nodes': nodes,
    'postProcessResults': serializers.serialize(
      graph._postProcessBuildStepResults,
      specifiedType: postProcessBuildStepResultsFullType,
    ),
    'phasedAssetDeps': serializedPhasedAssetDeps,
    'buildStepResults': serializers.serialize(
      BuiltMap<BuildStepId, BuildStepResult>.of(graph.buildStepResults),
      specifiedType: const FullType(BuiltMap, [
        FullType(BuildStepId),
        FullType(BuildStepResult),
      ]),
    ),
    'globResults': serializers.serialize(
      BuiltMap<GlobId, GlobResult>.of(graph.globResults),
      specifiedType: const FullType(BuiltMap, [
        FullType(GlobId),
        FullType(GlobResult),
      ]),
    ),
  };

  identityAssetIdSerializer.reset();
  return result;
}
