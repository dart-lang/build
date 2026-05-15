// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'serializers.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializers _$serializers =
    (Serializers().toBuilder()
          ..add(AssetDeps.serializer)
          ..add(AssetNode.serializer)
          ..add(BuildPlanDigest.serializer)
          ..add(BuildStepId.serializer)
          ..add(BuildStepResult.serializer)
          ..add(ExpiringValue.serializer)
          ..add(GlobId.serializer)
          ..add(GlobResult.serializer)
          ..add(NodeType.serializer)
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
          )
          ..addBuilderFactory(
            const FullType(BuiltSet, const [const FullType(AssetId)]),
            () => SetBuilder<AssetId>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltSet, const [const FullType(AssetId)]),
            () => SetBuilder<AssetId>(),
          ))
        .build();

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
