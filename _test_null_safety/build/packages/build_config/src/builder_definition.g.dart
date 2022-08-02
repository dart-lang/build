// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'builder_definition.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BuilderDefinition _$BuilderDefinitionFromJson(Map json) => $checkedCreate(
      'BuilderDefinition',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          allowedKeys: const [
            'builder_factories',
            'import',
            'build_extensions',
            'target',
            'auto_apply',
            'required_inputs',
            'runs_before',
            'applies_builders',
            'is_optional',
            'build_to',
            'defaults'
          ],
          requiredKeys: const [
            'builder_factories',
            'import',
            'build_extensions'
          ],
          disallowNullValues: const [
            'builder_factories',
            'import',
            'build_extensions'
          ],
        );
        final val = BuilderDefinition(
          builderFactories: $checkedConvert('builder_factories',
              (v) => (v as List<dynamic>).map((e) => e as String).toList()),
          buildExtensions: $checkedConvert(
              'build_extensions',
              (v) => (v as Map).map(
                    (k, e) => MapEntry(k as String,
                        (e as List<dynamic>).map((e) => e as String).toList()),
                  )),
          import: $checkedConvert('import', (v) => v as String),
          target: $checkedConvert('target', (v) => v as String?),
          autoApply: $checkedConvert(
              'auto_apply', (v) => $enumDecodeNullable(_$AutoApplyEnumMap, v)),
          requiredInputs: $checkedConvert('required_inputs',
              (v) => (v as List<dynamic>?)?.map((e) => e as String)),
          runsBefore: $checkedConvert('runs_before',
              (v) => (v as List<dynamic>?)?.map((e) => e as String)),
          appliesBuilders: $checkedConvert('applies_builders',
              (v) => (v as List<dynamic>?)?.map((e) => e as String)),
          isOptional: $checkedConvert('is_optional', (v) => v as bool?),
          buildTo: $checkedConvert(
              'build_to', (v) => $enumDecodeNullable(_$BuildToEnumMap, v)),
          defaults: $checkedConvert(
              'defaults',
              (v) => v == null
                  ? null
                  : TargetBuilderConfigDefaults.fromJson(v as Map)),
        );
        return val;
      },
      fieldKeyMap: const {
        'builderFactories': 'builder_factories',
        'buildExtensions': 'build_extensions',
        'autoApply': 'auto_apply',
        'requiredInputs': 'required_inputs',
        'runsBefore': 'runs_before',
        'appliesBuilders': 'applies_builders',
        'isOptional': 'is_optional',
        'buildTo': 'build_to'
      },
    );

const _$AutoApplyEnumMap = {
  AutoApply.none: 'none',
  AutoApply.dependents: 'dependents',
  AutoApply.allPackages: 'all_packages',
  AutoApply.rootPackage: 'root_package',
};

const _$BuildToEnumMap = {
  BuildTo.source: 'source',
  BuildTo.cache: 'cache',
};

PostProcessBuilderDefinition _$PostProcessBuilderDefinitionFromJson(Map json) =>
    $checkedCreate(
      'PostProcessBuilderDefinition',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          allowedKeys: const [
            'builder_factory',
            'import',
            'input_extensions',
            'target',
            'defaults'
          ],
          requiredKeys: const ['builder_factory', 'import'],
          disallowNullValues: const ['builder_factory', 'import'],
        );
        final val = PostProcessBuilderDefinition(
          builderFactory:
              $checkedConvert('builder_factory', (v) => v as String),
          import: $checkedConvert('import', (v) => v as String),
          inputExtensions: $checkedConvert('input_extensions',
              (v) => (v as List<dynamic>?)?.map((e) => e as String)),
          target: $checkedConvert('target', (v) => v as String?),
          defaults: $checkedConvert(
              'defaults',
              (v) => v == null
                  ? null
                  : TargetBuilderConfigDefaults.fromJson(v as Map)),
        );
        return val;
      },
      fieldKeyMap: const {
        'builderFactory': 'builder_factory',
        'inputExtensions': 'input_extensions'
      },
    );

TargetBuilderConfigDefaults _$TargetBuilderConfigDefaultsFromJson(Map json) =>
    $checkedCreate(
      'TargetBuilderConfigDefaults',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          allowedKeys: const [
            'generate_for',
            'options',
            'dev_options',
            'release_options'
          ],
        );
        final val = TargetBuilderConfigDefaults(
          generateFor: $checkedConvert(
              'generate_for', (v) => v == null ? null : InputSet.fromJson(v)),
          options: $checkedConvert(
              'options',
              (v) => (v as Map?)?.map(
                    (k, e) => MapEntry(k as String, e),
                  )),
          devOptions: $checkedConvert(
              'dev_options',
              (v) => (v as Map?)?.map(
                    (k, e) => MapEntry(k as String, e),
                  )),
          releaseOptions: $checkedConvert(
              'release_options',
              (v) => (v as Map?)?.map(
                    (k, e) => MapEntry(k as String, e),
                  )),
        );
        return val;
      },
      fieldKeyMap: const {
        'generateFor': 'generate_for',
        'devOptions': 'dev_options',
        'releaseOptions': 'release_options'
      },
    );
