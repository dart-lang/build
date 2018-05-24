// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'build_target.dart';

// **************************************************************************
// Generator: JsonSerializableGenerator
// **************************************************************************

BuildTarget _$BuildTargetFromJson(Map json) => $checkedNew(
    'BuildTarget',
    json,
    () => new BuildTarget(
        sources: $checkedConvert(json, 'sources',
            (v) => v == null ? null : new InputSet.fromJson(v)),
        dependencies: $checkedConvert(
            json, 'dependencies', (v) => (v as List)?.map((e) => e as String)),
        builders: $checkedConvert(
            json,
            'builders',
            (v) => (v as Map)?.map((k, e) => new MapEntry(
                k as String,
                e == null
                    ? null
                    : new TargetBuilderConfig.fromJson(e as Map))))));

TargetBuilderConfig _$TargetBuilderConfigFromJson(Map json) => $checkedNew(
        'TargetBuilderConfig',
        json,
        () => new TargetBuilderConfig(
            isEnabled: $checkedConvert(json, 'is_enabled', (v) => v as bool),
            generateFor: $checkedConvert(json, 'generate_for',
                (v) => v == null ? null : new InputSet.fromJson(v)),
            options: $checkedConvert(json, 'options',
                (v) => v == null ? null : builderOptionsFromJson(v as Map)),
            devOptions: $checkedConvert(json, 'dev_options',
                (v) => v == null ? null : builderOptionsFromJson(v as Map)),
            releaseOptions: $checkedConvert(json, 'release_options',
                (v) => v == null ? null : builderOptionsFromJson(v as Map))),
        fieldKeyMap: const {
          'isEnabled': 'is_enabled',
          'generateFor': 'generate_for',
          'devOptions': 'dev_options',
          'releaseOptions': 'release_options'
        });
