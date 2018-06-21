// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'build_config.dart';

// **************************************************************************
// Generator: JsonSerializableGenerator
// **************************************************************************

BuildConfig _$BuildConfigFromJson(Map json) {
  return $checkedNew('BuildConfig', json, () {
    $checkKeys(json, allowedKeys: const [
      'builders',
      'post_process_builders',
      'targets',
      'global_options'
    ]);
    var val = new BuildConfig(
        buildTargets: $checkedConvert(json, 'targets',
            (v) => v == null ? null : _buildTargetsFromJson(v as Map)),
        globalOptions: $checkedConvert(
            json,
            'global_options',
            (v) => (v as Map)?.map((k, e) => new MapEntry(
                k as String,
                e == null
                    ? null
                    : new GlobalBuilderConfig.fromJson(e as Map)))),
        builderDefinitions: $checkedConvert(
            json,
            'builders',
            (v) => (v as Map)?.map((k, e) => new MapEntry(k as String,
                e == null ? null : new BuilderDefinition.fromJson(e as Map)))),
        postProcessBuilderDefinitions: $checkedConvert(
            json,
            'post_process_builders',
            (v) => (v as Map)?.map((k, e) => new MapEntry(
                k as String,
                e == null
                    ? null
                    : new PostProcessBuilderDefinition.fromJson(e as Map)))));
    return val;
  }, fieldKeyMap: const {
    'buildTargets': 'targets',
    'globalOptions': 'global_options',
    'builderDefinitions': 'builders',
    'postProcessBuilderDefinitions': 'post_process_builders'
  });
}
