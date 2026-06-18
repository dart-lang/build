// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'build_state.dart';

/// Deserializes an [BuildState] from a [Map].
///
/// Returns `null` if deserialization fails.
BuildState? deserializeBuildState(Map serializedBuildState) {
  final buildState = BuildState();

  final sourceIds =
      serializers.deserialize(
            serializedBuildState['sourceIds'],
            specifiedType: const FullType(BuiltSet, [FullType(AssetId)]),
          )
          as BuiltSet<AssetId>;
  final sourceContents =
      serializers.deserialize(
            serializedBuildState['sourceContents'],
            specifiedType: const FullType(BuiltMap, [
              FullType(AssetId),
              FullType(AssetContent),
            ]),
          )
          as BuiltMap<AssetId, AssetContent>;

  for (final id in sourceIds) {
    buildState._sources.add(id, digest: sourceContents[id]);
  }

  final postProcessResults =
      serializers.deserialize(
            serializedBuildState['postProcessResults'],
            specifiedType: postProcessBuildStepResultsFullType,
          )
          as BuiltMap<PostProcessBuildStepId, PostProcessBuildStepResult>;

  for (final entry in postProcessResults.entries) {
    buildState.addPostProcessBuildStepResult(entry.key, entry.value);
  }

  if (serializedBuildState.containsKey('missingSources')) {
    final deserialized =
        serializers.deserialize(
              serializedBuildState['missingSources'],
              specifiedType: const FullType(BuiltSet, [FullType(AssetId)]),
            )
            as BuiltSet<AssetId>;
    buildState._sources.missingSources.addAll(deserialized.toSet());
  }

  if (serializedBuildState.containsKey('buildStepResults')) {
    final deserialized =
        serializers.deserialize(
              serializedBuildState['buildStepResults'],
              specifiedType: const FullType(BuiltMap, [
                FullType(BuildStepId),
                FullType(BuildStepResult),
              ]),
            )
            as BuiltMap<BuildStepId, BuildStepResult>;
    for (final entry in deserialized.entries) {
      buildState.updateBuildStepResult(entry.key, entry.value);
    }
  }

  if (serializedBuildState.containsKey('globResults')) {
    final deserialized =
        serializers.deserialize(
              serializedBuildState['globResults'],
              specifiedType: const FullType(BuiltMap, [
                FullType(GlobId),
                FullType(GlobResult),
              ]),
            )
            as BuiltMap<GlobId, GlobResult>;
    for (final entry in deserialized.entries) {
      buildState.updateGlobResult(entry.key, entry.value);
    }
  }

  return buildState;
}

/// Serializes an [BuildState] into a [Map].
Map<String, Object?> serializeBuildState(BuildState buildState) {
  final result = <String, Object?>{
    'sourceIds': serializers.serialize(
      BuiltSet<AssetId>.of(buildState._sources.sources.keys),
      specifiedType: const FullType(BuiltSet, [FullType(AssetId)]),
    ),
    'sourceContents': serializers.serialize(
      BuiltMap<AssetId, AssetContent>.of({
        for (final entry in buildState._sources.sources.entries)
          if (entry.value != null) entry.key: entry.value!,
      }),
      specifiedType: const FullType(BuiltMap, [
        FullType(AssetId),
        FullType(AssetContent),
      ]),
    ),
    'postProcessResults': serializers.serialize(
      BuiltMap<PostProcessBuildStepId, PostProcessBuildStepResult>.of({
        for (final outer in buildState._postProcessResultsByInput.entries)
          for (final inner in outer.value.entries)
            PostProcessBuildStepId(input: outer.key, actionNumber: inner.key):
                inner.value,
      }),
      specifiedType: postProcessBuildStepResultsFullType,
    ),
    'missingSources': serializers.serialize(
      BuiltSet<AssetId>.of(buildState._sources.missingSources),
      specifiedType: const FullType(BuiltSet, [FullType(AssetId)]),
    ),
    'buildStepResults': serializers.serialize(
      BuiltMap<BuildStepId, BuildStepResult>.of({
        for (final outer in buildState._buildStepResultsByPrimaryInput.entries)
          for (final inner in outer.value.entries)
            BuildStepId(primaryInput: outer.key, phaseNumber: inner.key):
                inner.value,
      }),
      specifiedType: const FullType(BuiltMap, [
        FullType(BuildStepId),
        FullType(BuildStepResult),
      ]),
    ),
    'globResults': serializers.serialize(
      BuiltMap<GlobId, GlobResult>.of(buildState._globResults),
      specifiedType: const FullType(BuiltMap, [
        FullType(GlobId),
        FullType(GlobResult),
      ]),
    ),
  };

  return result;
}
