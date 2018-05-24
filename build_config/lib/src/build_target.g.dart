// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'build_target.dart';

// **************************************************************************
// Generator: JsonSerializableGenerator
// **************************************************************************

BuildTarget _$BuildTargetFromJson(Map<String, dynamic> json) => new BuildTarget(
    sources:
        json['sources'] == null ? null : new InputSet.fromJson(json['sources']),
    dependencies: (json['dependencies'] as List)?.map((e) => e as String),
    builders: (json['builders'] as Map<String, dynamic>)?.map((k, e) =>
        new MapEntry(
            k,
            e == null
                ? null
                : new TargetBuilderConfig.fromJson(
                    e as Map<String, dynamic>))));

TargetBuilderConfig _$TargetBuilderConfigFromJson(Map<String, dynamic> json) =>
    new TargetBuilderConfig(
        isEnabled: json['is_enabled'] as bool,
        generateFor: json['generate_for'] == null
            ? null
            : new InputSet.fromJson(json['generate_for']),
        options: json['options'] == null
            ? null
            : builderOptionsFromJson(json['options'] as Map<String, dynamic>),
        devOptions: json['dev_options'] == null
            ? null
            : builderOptionsFromJson(
                json['dev_options'] as Map<String, dynamic>),
        releaseOptions: json['release_options'] == null
            ? null
            : builderOptionsFromJson(
                json['release_options'] as Map<String, dynamic>));
