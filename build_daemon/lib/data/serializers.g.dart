// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'serializers.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializers _$serializers = (new Serializers().toBuilder()
      ..add(BuildRequest.serializer)
      ..add(BuildResults.serializer)
      ..add(BuildStatus.serializer)
      ..add(BuildTargetRequest.serializer)
      ..add(DefaultBuildResult.serializer)
      ..add(DefaultBuildTarget.serializer)
      ..add(ServerLog.serializer)
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(BuildResult)]),
          () => new ListBuilder<BuildResult>())
      ..addBuilderFactory(
          const FullType(BuiltSet, const [const FullType(RegExp)]),
          () => new SetBuilder<RegExp>())
      ..addBuilderFactory(
          const FullType(
              Map, const [const FullType(String), const FullType(dynamic)]),
          () => new MapBuilder<String, dynamic>()))
    .build();

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
