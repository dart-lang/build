// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'builder_definition.dart';

// **************************************************************************
// Generator: JsonSerializableGenerator
// **************************************************************************

BuilderDefinition _$BuilderDefinitionFromJson(Map<String, dynamic> json) =>
    new BuilderDefinition(
        builderFactories: (json['builder_factories'] as List)
            .map((e) => e as String)
            .toList(),
        buildExtensions: (json['build_extensions'] as Map<String, dynamic>).map(
            (k, e) =>
                new MapEntry(k, (e as List).map((e) => e as String).toList())),
        import: json['import'] as String,
        target: json['target'] as String,
        autoApply: json['auto_apply'] == null
            ? null
            : _autoApplyFromJson(json['auto_apply'] as String),
        requiredInputs:
            (json['required_inputs'] as List)?.map((e) => e as String),
        runsBefore: (json['runs_before'] as List)?.map((e) => e as String),
        appliesBuilders:
            (json['applies_builders'] as List)?.map((e) => e as String),
        isOptional: json['is_optional'] as bool,
        buildTo: json['build_to'] == null
            ? null
            : _buildToFromJson(json['build_to'] as String),
        defaults: json['defaults'] == null
            ? null
            : new TargetBuilderConfigDefaults.fromJson(
                json['defaults'] as Map<String, dynamic>));

PostProcessBuilderDefinition _$PostProcessBuilderDefinitionFromJson(
        Map<String, dynamic> json) =>
    new PostProcessBuilderDefinition(
        builderFactory: json['builder_factory'] as String,
        import: json['import'] as String,
        inputExtensions:
            (json['input_extensions'] as List)?.map((e) => e as String),
        target: json['target'] as String,
        defaults: json['defaults'] == null
            ? null
            : new TargetBuilderConfigDefaults.fromJson(
                json['defaults'] as Map<String, dynamic>));

TargetBuilderConfigDefaults _$TargetBuilderConfigDefaultsFromJson(
        Map<String, dynamic> json) =>
    new TargetBuilderConfigDefaults(
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
