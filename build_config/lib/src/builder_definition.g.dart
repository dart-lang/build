// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'builder_definition.dart';

// **************************************************************************
// Generator: JsonSerializableGenerator
// **************************************************************************

BuilderDefinition _$BuilderDefinitionFromJson(Map json) {
  return $checkedNew('BuilderDefinition', json, () {
    var val = new BuilderDefinition(
        builderFactories: $checkedConvert(json, 'builder_factories',
            (v) => (v as List).map((e) => e as String).toList()),
        buildExtensions: $checkedConvert(
            json,
            'build_extensions',
            (v) => (v as Map).map((k, e) => new MapEntry(
                k as String, (e as List).map((e) => e as String).toList()))),
        import: $checkedConvert(json, 'import', (v) => v as String),
        target: $checkedConvert(json, 'target', (v) => v as String),
        autoApply: $checkedConvert(json, 'auto_apply',
            (v) => v == null ? null : _autoApplyFromJson(v as String)),
        requiredInputs: $checkedConvert(json, 'required_inputs',
            (v) => (v as List)?.map((e) => e as String)),
        runsBefore: $checkedConvert(
            json, 'runs_before', (v) => (v as List)?.map((e) => e as String)),
        appliesBuilders: $checkedConvert(json, 'applies_builders',
            (v) => (v as List)?.map((e) => e as String)),
        isOptional: $checkedConvert(json, 'is_optional', (v) => v as bool),
        buildTo: $checkedConvert(json, 'build_to',
            (v) => v == null ? null : _buildToFromJson(v as String)),
        defaults: $checkedConvert(
            json,
            'defaults',
            (v) => v == null
                ? null
                : new TargetBuilderConfigDefaults.fromJson(v as Map)));
    return val;
  }, fieldKeyMap: const {
    'builderFactories': 'builder_factories',
    'buildExtensions': 'build_extensions',
    'autoApply': 'auto_apply',
    'requiredInputs': 'required_inputs',
    'runsBefore': 'runs_before',
    'appliesBuilders': 'applies_builders',
    'isOptional': 'is_optional',
    'buildTo': 'build_to'
  });
}

PostProcessBuilderDefinition _$PostProcessBuilderDefinitionFromJson(Map json) {
  return $checkedNew('PostProcessBuilderDefinition', json, () {
    var val = new PostProcessBuilderDefinition(
        builderFactory:
            $checkedConvert(json, 'builder_factory', (v) => v as String),
        import: $checkedConvert(json, 'import', (v) => v as String),
        inputExtensions: $checkedConvert(json, 'input_extensions',
            (v) => (v as List)?.map((e) => e as String)),
        target: $checkedConvert(json, 'target', (v) => v as String),
        defaults: $checkedConvert(
            json,
            'defaults',
            (v) => v == null
                ? null
                : new TargetBuilderConfigDefaults.fromJson(v as Map)));
    return val;
  }, fieldKeyMap: const {
    'builderFactory': 'builder_factory',
    'inputExtensions': 'input_extensions'
  });
}

TargetBuilderConfigDefaults _$TargetBuilderConfigDefaultsFromJson(Map json) {
  return $checkedNew('TargetBuilderConfigDefaults', json, () {
    var val = new TargetBuilderConfigDefaults(
        generateFor: $checkedConvert(json, 'generate_for',
            (v) => v == null ? null : new InputSet.fromJson(v)),
        options: $checkedConvert(json, 'options',
            (v) => v == null ? null : builderOptionsFromJson(v as Map)),
        devOptions: $checkedConvert(json, 'dev_options',
            (v) => v == null ? null : builderOptionsFromJson(v as Map)),
        releaseOptions: $checkedConvert(json, 'release_options',
            (v) => v == null ? null : builderOptionsFromJson(v as Map)));
    return val;
  }, fieldKeyMap: const {
    'generateFor': 'generate_for',
    'devOptions': 'dev_options',
    'releaseOptions': 'release_options'
  });
}
