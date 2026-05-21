// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'graph.dart';

/// Part of the serialized graph, used to ensure versioning constraints.
///
/// This should be incremented any time the serialize/deserialize formats
/// change.

/// Deserializes an [BuildState] from a [Map].
///
/// Returns `null` if deserialization fails.
BuildState? deserializeAssetGraph(Map serializedGraph) {
  final graph = BuildState.empty();

  final sourceIds =
      serializers.deserialize(
            serializedGraph['sourceIds'],
            specifiedType: const FullType(BuiltSet, [FullType(AssetId)]),
          )
          as BuiltSet<AssetId>;
  final sourceDigests =
      serializers.deserialize(
            serializedGraph['sourceDigests'],
            specifiedType: const FullType(BuiltMap, [
              FullType(AssetId),
              FullType(Digest),
            ]),
          )
          as BuiltMap<AssetId, Digest>;

  for (final id in sourceIds) {
    graph.addSourceForTest(id, digest: sourceDigests[id]);
  }

  final postProcessResults =
      serializers.deserialize(
            serializedGraph['postProcessResults'],
            specifiedType: postProcessBuildStepResultsFullType,
          )
          as BuiltMap<PostProcessBuildStepId, PostProcessBuildStepResult>;

  for (final entry in postProcessResults.entries) {
    graph.addPostProcessBuildStepResult(entry.key, entry.value);
  }

  if (serializedGraph.containsKey('missingSources')) {
    final deserialized =
        serializers.deserialize(
              serializedGraph['missingSources'],
              specifiedType: const FullType(BuiltSet, [FullType(AssetId)]),
            )
            as BuiltSet<AssetId>;
    graph._sources.missingSources.addAll(deserialized.toSet());
  }

  if (serializedGraph.containsKey('buildStepResults')) {
    final deserialized =
        serializers.deserialize(
              serializedGraph['buildStepResults'],
              specifiedType: const FullType(BuiltMap, [
                FullType(BuildStepId),
                FullType(BuildStepResult),
              ]),
            )
            as BuiltMap<BuildStepId, BuildStepResult>;
    for (final entry in deserialized.entries) {
      graph.updateBuildStepResult(entry.key, entry.value);
    }
  }

  if (serializedGraph.containsKey('globResults')) {
    final deserialized =
        serializers.deserialize(
              serializedGraph['globResults'],
              specifiedType: const FullType(BuiltMap, [
                FullType(GlobId),
                FullType(GlobResult),
              ]),
            )
            as BuiltMap<GlobId, GlobResult>;
    for (final entry in deserialized.entries) {
      graph.updateGlobResult(entry.key, entry.value);
    }
  }

  if (serializedGraph.containsKey('buildStepsByDeclaredOutput')) {
    final deserialized =
        serializers.deserialize(
              serializedGraph['buildStepsByDeclaredOutput'],
              specifiedType: const FullType(BuiltMap, [
                FullType(AssetId),
                FullType(BuildStepId),
              ]),
            )
            as BuiltMap<AssetId, BuildStepId>;
    graph._buildStepsByDeclaredOutput.addAll(deserialized.toMap());
  }

  if (serializedGraph.containsKey('declaredPrimaryOutputsByPrimaryInput')) {
    final deserialized =
        serializers.deserialize(
              serializedGraph['declaredPrimaryOutputsByPrimaryInput'],
              specifiedType: const FullType(BuiltMap, [
                FullType(AssetId),
                FullType(BuiltSet, [FullType(AssetId)]),
              ]),
            )
            as BuiltMap<AssetId, BuiltSet<AssetId>>;
    for (final entry in deserialized.entries) {
      graph._declaredOutputsByPrimaryInput[entry.key] = entry.value.toSet();
    }
  }

  return graph;
}

/// Serializes an [BuildState] into a [Map].
Map<String, Object?> serializeAssetGraph(BuildState graph) {
  final result = <String, Object?>{
    'sourceIds': serializers.serialize(
      BuiltSet<AssetId>.of(graph._sources.sources.keys),
      specifiedType: const FullType(BuiltSet, [FullType(AssetId)]),
    ),
    'sourceDigests': serializers.serialize(
      BuiltMap<AssetId, Digest>.of({
        for (final entry in graph._sources.sources.entries)
          if (entry.value != null) entry.key: entry.value!,
      }),
      specifiedType: const FullType(BuiltMap, [
        FullType(AssetId),
        FullType(Digest),
      ]),
    ),
    'postProcessResults': serializers.serialize(
      BuiltMap<PostProcessBuildStepId, PostProcessBuildStepResult>.of(
        graph._postProcessBuildStepResults,
      ),
      specifiedType: postProcessBuildStepResultsFullType,
    ),
    'missingSources': serializers.serialize(
      BuiltSet<AssetId>.of(graph._sources.missingSources),
      specifiedType: const FullType(BuiltSet, [FullType(AssetId)]),
    ),
    'buildStepResults': serializers.serialize(
      BuiltMap<BuildStepId, BuildStepResult>.of(graph._buildStepResults),
      specifiedType: const FullType(BuiltMap, [
        FullType(BuildStepId),
        FullType(BuildStepResult),
      ]),
    ),
    'globResults': serializers.serialize(
      BuiltMap<GlobId, GlobResult>.of(graph._globResults),
      specifiedType: const FullType(BuiltMap, [
        FullType(GlobId),
        FullType(GlobResult),
      ]),
    ),
    'buildStepsByDeclaredOutput': serializers.serialize(
      BuiltMap<AssetId, BuildStepId>.of(graph._buildStepsByDeclaredOutput),
      specifiedType: const FullType(BuiltMap, [
        FullType(AssetId),
        FullType(BuildStepId),
      ]),
    ),
    'declaredPrimaryOutputsByPrimaryInput': serializers.serialize(
      BuiltMap<AssetId, BuiltSet<AssetId>>.of({
        for (final entry in graph._declaredOutputsByPrimaryInput.entries)
          entry.key: entry.value.toBuiltSet(),
      }),
      specifiedType: const FullType(BuiltMap, [
        FullType(AssetId),
        FullType(BuiltSet, [FullType(AssetId)]),
      ]),
    ),
  };

  return result;
}
