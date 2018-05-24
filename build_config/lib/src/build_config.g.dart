// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'build_config.dart';

// **************************************************************************
// Generator: JsonSerializableGenerator
// **************************************************************************

BuildConfig _$BuildConfigFromJson(Map<String, dynamic> json) => new BuildConfig(
    buildTargets: (json['targets'] as Map<String, dynamic>)?.map((k, e) =>
        new MapEntry(
            k,
            e == null
                ? null
                : new BuildTarget.fromJson(e as Map<String, dynamic>))),
    builderDefinitions: (json['builders'] as Map<String, dynamic>)?.map(
        (k, e) => new MapEntry(
            k,
            e == null
                ? null
                : new BuilderDefinition.fromJson(e as Map<String, Object>))),
    postProcessBuilderDefinitions:
        (json['post_process_builders'] as Map<String, dynamic>)?.map((k, e) =>
            new MapEntry(
                k, e == null ? null : new PostProcessBuilderDefinition.fromJson(e as Map<String, Object>))));
