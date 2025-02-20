// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'serializers.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializers _$serializers =
    (new Serializers().toBuilder()
          ..add(BuildRequest.serializer)
          ..add(BuildResults.serializer)
          ..add(BuildStatus.serializer)
          ..add(BuildTargetRequest.serializer)
          ..add(DefaultBuildResult.serializer)
          ..add(DefaultBuildTarget.serializer)
          ..add(Level.serializer)
          ..add(OutputLocation.serializer)
          ..add(ServerLog.serializer)
          ..add(ShutdownNotification.serializer)
          ..addBuilderFactory(
            const FullType(BuiltList, const [const FullType(BuildResult)]),
            () => new ListBuilder<BuildResult>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [const FullType(Uri)]),
            () => new ListBuilder<Uri>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltSet, const [const FullType(RegExp)]),
            () => new SetBuilder<RegExp>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltSet, const [const FullType(String)]),
            () => new SetBuilder<String>(),
          ))
        .build();

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
