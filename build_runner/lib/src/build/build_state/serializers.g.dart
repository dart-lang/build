// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'serializers.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializers _$serializers =
    (Serializers().toBuilder()
          ..add(AssetDeps.serializer)
          ..add(BuildSpecDigest.serializer)
          ..add(BuildStepId.serializer)
          ..add(BuildStepResult.serializer)
          ..add(ExpiringValue.serializer)
          ..add(GlobId.serializer)
          ..add(GlobResult.serializer)
          ..add(IncrementalBuildState.serializer)
          ..add(PhasedAssetDeps.serializer)
          ..add(PhasedValue.serializer)
          ..add(PostProcessBuildStepId.serializer)
          ..add(PostProcessBuildStepResult.serializer)
          ..addBuilderFactory(
            const FullType(BuiltList, const [const FullType(String)]),
            () => ListBuilder<String>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltMap, const [
              const FullType(String),
              const FullType.nullable(String),
            ]),
            () => MapBuilder<String, String?>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [const FullType(String)]),
            () => ListBuilder<String>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [const FullType(String)]),
            () => ListBuilder<String>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltMap, const [
              const FullType(AssetId),
              const FullType(PhasedValue, const [const FullType(AssetDeps)]),
            ]),
            () => MapBuilder<AssetId, PhasedValue<AssetDeps>>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltSet, const [const FullType(AssetId)]),
            () => SetBuilder<AssetId>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltSet, const [const FullType(AssetId)]),
            () => SetBuilder<AssetId>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [const FullType(String)]),
            () => ListBuilder<String>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltSet, const [const FullType(AssetId)]),
            () => SetBuilder<AssetId>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltMap, const [
              const FullType(AssetId),
              const FullType(Digest),
            ]),
            () => MapBuilder<AssetId, Digest>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltSet, const [const FullType(AssetId)]),
            () => SetBuilder<AssetId>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltMap, const [
              const FullType(BuildStepId),
              const FullType(BuildStepResult),
            ]),
            () => MapBuilder<BuildStepId, BuildStepResult>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltMap, const [
              const FullType(PostProcessBuildStepId),
              const FullType(PostProcessBuildStepResult),
            ]),
            () =>
                MapBuilder<
                  PostProcessBuildStepId,
                  PostProcessBuildStepResult
                >(),
          )
          ..addBuilderFactory(
            const FullType(BuiltMap, const [
              const FullType(GlobId),
              const FullType(GlobResult),
            ]),
            () => MapBuilder<GlobId, GlobResult>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltSet, const [const FullType(AssetId)]),
            () => SetBuilder<AssetId>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltSet, const [const FullType(AssetId)]),
            () => SetBuilder<AssetId>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltSet, const [const FullType(AssetId)]),
            () => SetBuilder<AssetId>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltSet, const [const FullType(AssetId)]),
            () => SetBuilder<AssetId>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltSet, const [const FullType(GlobId)]),
            () => SetBuilder<GlobId>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltSet, const [const FullType(AssetId)]),
            () => SetBuilder<AssetId>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [const FullType(String)]),
            () => ListBuilder<String>(),
          ))
        .build();

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
