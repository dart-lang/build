// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'build_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BuildConfig _$BuildConfigFromJson(Map json) => $checkedCreate(
      'BuildConfig',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          allowedKeys: const [
            'builders',
            'post_process_builders',
            'targets',
            'global_options',
            'additional_public_assets'
          ],
        );
        final val = BuildConfig(
          buildTargets: $checkedConvert(
              'targets', (v) => _buildTargetsFromJson(v as Map?)),
          globalOptions: $checkedConvert(
              'global_options',
              (v) => (v as Map?)?.map(
                    (k, e) => MapEntry(
                        k as String, GlobalBuilderConfig.fromJson(e as Map)),
                  )),
          builderDefinitions: $checkedConvert(
              'builders',
              (v) => (v as Map?)?.map(
                    (k, e) => MapEntry(
                        k as String, BuilderDefinition.fromJson(e as Map)),
                  )),
          postProcessBuilderDefinitions: $checkedConvert(
              'post_process_builders',
              (v) =>
                  (v as Map?)?.map(
                    (k, e) => MapEntry(k as String,
                        PostProcessBuilderDefinition.fromJson(e as Map)),
                  ) ??
                  const {}),
          additionalPublicAssets: $checkedConvert(
              'additional_public_assets',
              (v) =>
                  (v as List<dynamic>?)?.map((e) => e as String).toList() ??
                  const []),
        );
        return val;
      },
      fieldKeyMap: const {
        'buildTargets': 'targets',
        'globalOptions': 'global_options',
        'builderDefinitions': 'builders',
        'postProcessBuilderDefinitions': 'post_process_builders',
        'additionalPublicAssets': 'additional_public_assets'
      },
    );
