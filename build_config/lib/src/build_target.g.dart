// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'build_target.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BuildTarget _$BuildTargetFromJson(Map json) {
  return $checkedNew('BuildTarget', json, () {
    $checkKeys(json,
        allowedKeys: const ['builders', 'dependencies', 'sources']);
    var val = BuildTarget(
        sources: $checkedConvert(
            json, 'sources', (v) => v == null ? null : InputSet.fromJson(v)),
        dependencies: $checkedConvert(
            json, 'dependencies', (v) => (v as List)?.map((e) => e as String)),
        builders: $checkedConvert(
            json,
            'builders',
            (v) => (v as Map)?.map((k, e) => MapEntry(k as String,
                e == null ? null : TargetBuilderConfig.fromJson(e as Map)))));
    return val;
  });
}

TargetBuilderConfig _$TargetBuilderConfigFromJson(Map json) {
  return $checkedNew('TargetBuilderConfig', json, () {
    $checkKeys(json, allowedKeys: const [
      'enabled',
      'generate_for',
      'options',
      'dev_options',
      'release_options'
    ]);
    var val = TargetBuilderConfig(
        isEnabled: $checkedConvert(json, 'enabled', (v) => v as bool),
        generateFor: $checkedConvert(json, 'generate_for',
            (v) => v == null ? null : InputSet.fromJson(v)),
        options: $checkedConvert(json, 'options',
            (v) => v == null ? null : builderOptionsFromJson(v as Map)),
        devOptions: $checkedConvert(json, 'dev_options',
            (v) => v == null ? null : builderOptionsFromJson(v as Map)),
        releaseOptions: $checkedConvert(json, 'release_options',
            (v) => v == null ? null : builderOptionsFromJson(v as Map)));
    return val;
  }, fieldKeyMap: const {
    'isEnabled': 'enabled',
    'generateFor': 'generate_for',
    'devOptions': 'dev_options',
    'releaseOptions': 'release_options'
  });
}

GlobalBuilderConfig _$GlobalBuilderConfigFromJson(Map json) {
  return $checkedNew('GlobalBuilderConfig', json, () {
    $checkKeys(json,
        allowedKeys: const ['options', 'dev_options', 'release_options']);
    var val = GlobalBuilderConfig(
        options: $checkedConvert(json, 'options',
            (v) => v == null ? null : builderOptionsFromJson(v as Map)),
        devOptions: $checkedConvert(json, 'dev_options',
            (v) => v == null ? null : builderOptionsFromJson(v as Map)),
        releaseOptions: $checkedConvert(json, 'release_options',
            (v) => v == null ? null : builderOptionsFromJson(v as Map)));
    return val;
  }, fieldKeyMap: const {
    'devOptions': 'dev_options',
    'releaseOptions': 'release_options'
  });
}
