// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'build_state.dart';

/// Deserializes an [BuildState] from a [Map].
///
/// Returns `null` if deserialization fails.
BuildState? deserializeBuildState(Map serializedBuildState) {
  final buildState = BuildState.empty();

  final sourceIds =
      serializers.deserialize(
            serializedBuildState['sourceIds'],
            specifiedType: const FullType(BuiltSet, [FullType(AssetId)]),
          )
          as BuiltSet<AssetId>;
  final sourceDigests =
      serializers.deserialize(
            serializedBuildState['sourceDigests'],
            specifiedType: const FullType(BuiltMap, [
              FullType(AssetId),
              FullType(Digest),
            ]),
          )
          as BuiltMap<AssetId, Digest>;

  for (final id in sourceIds) {
    buildState._sources.add(id, digest: sourceDigests[id]);
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

  if (serializedBuildState.containsKey('buildStepsByDeclaredOutput')) {
    final deserialized =
        serializers.deserialize(
              serializedBuildState['buildStepsByDeclaredOutput'],
              specifiedType: const FullType(BuiltMap, [
                FullType(AssetId),
                FullType(BuildStepId),
              ]),
            )
            as BuiltMap<AssetId, BuildStepId>;
    buildState._buildStepsByDeclaredOutput.addAll(deserialized.toMap());
  }

  if (serializedBuildState.containsKey(
    'declaredPrimaryOutputsByPrimaryInput',
  )) {
    final deserialized =
        serializers.deserialize(
              serializedBuildState['declaredPrimaryOutputsByPrimaryInput'],
              specifiedType: const FullType(BuiltMap, [
                FullType(AssetId),
                FullType(BuiltSet, [FullType(AssetId)]),
              ]),
            )
            as BuiltMap<AssetId, BuiltSet<AssetId>>;
    for (final entry in deserialized.entries) {
      buildState._declaredOutputsByPrimaryInput[entry.key] =
          entry.value.toSet();
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
    'sourceDigests': serializers.serialize(
      BuiltMap<AssetId, Digest>.of({
        for (final entry in buildState._sources.sources.entries)
          if (entry.value != null) entry.key: entry.value!,
      }),
      specifiedType: const FullType(BuiltMap, [
        FullType(AssetId),
        FullType(Digest),
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
    'buildStepsByDeclaredOutput': serializers.serialize(
      BuiltMap<AssetId, BuildStepId>.of(buildState._buildStepsByDeclaredOutput),
      specifiedType: const FullType(BuiltMap, [
        FullType(AssetId),
        FullType(BuildStepId),
      ]),
    ),
    'declaredPrimaryOutputsByPrimaryInput': serializers.serialize(
      BuiltMap<AssetId, BuiltSet<AssetId>>.of({
        for (final entry in buildState._declaredOutputsByPrimaryInput.entries)
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
