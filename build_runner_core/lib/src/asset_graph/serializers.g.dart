// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'serializers.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializers _$serializers =
    (new Serializers().toBuilder()
          ..add(AssetDeps.serializer)
          ..add(AssetNode.serializer)
          ..add(ExpiringValue.serializer)
          ..add(GeneratedNodeConfiguration.serializer)
          ..add(GeneratedNodeState.serializer)
          ..add(GlobNodeConfiguration.serializer)
          ..add(GlobNodeState.serializer)
          ..add(NodeType.serializer)
          ..add(PhasedAssetDeps.serializer)
          ..add(PhasedValue.serializer)
          ..add(PostProcessBuildStepId.serializer)
          ..addBuilderFactory(
            const FullType(BuiltMap, const [
              const FullType(AssetId),
              const FullType(PhasedValue, const [const FullType(AssetDeps)]),
            ]),
            () => new MapBuilder<AssetId, PhasedValue<AssetDeps>>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltSet, const [const FullType(AssetId)]),
            () => new SetBuilder<AssetId>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltSet, const [const FullType(AssetId)]),
            () => new SetBuilder<AssetId>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [const FullType(AssetId)]),
            () => new ListBuilder<AssetId>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltSet, const [const FullType(AssetId)]),
            () => new SetBuilder<AssetId>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltSet, const [const FullType(AssetId)]),
            () => new SetBuilder<AssetId>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltSet, const [const FullType(AssetId)]),
            () => new SetBuilder<AssetId>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltSet, const [
              const FullType(PostProcessBuildStepId),
            ]),
            () => new SetBuilder<PostProcessBuildStepId>(),
          ))
        .build();

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
