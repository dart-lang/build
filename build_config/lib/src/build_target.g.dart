// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'build_target.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BuildTarget _$BuildTargetFromJson(Map json) => $checkedCreate(
      'BuildTarget',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          allowedKeys: const [
            'auto_apply_builders',
            'builders',
            'dependencies',
            'sources'
          ],
        );
        final val = BuildTarget(
          autoApplyBuilders:
              $checkedConvert('auto_apply_builders', (v) => v as bool?),
          sources: $checkedConvert(
              'sources', (v) => v == null ? null : InputSet.fromJson(v)),
          dependencies: $checkedConvert('dependencies',
              (v) => (v as List<dynamic>?)?.map((e) => e as String)),
          builders: $checkedConvert(
              'builders',
              (v) => (v as Map?)?.map(
                    (k, e) => MapEntry(
                        k as String, TargetBuilderConfig.fromJson(e as Map)),
                  )),
        );
        return val;
      },
      fieldKeyMap: const {'autoApplyBuilders': 'auto_apply_builders'},
    );

TargetBuilderConfig _$TargetBuilderConfigFromJson(Map json) => $checkedCreate(
      'TargetBuilderConfig',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          allowedKeys: const [
            'enabled',
            'generate_for',
            'options',
            'dev_options',
            'release_options'
          ],
        );
        final val = TargetBuilderConfig(
          isEnabled: $checkedConvert('enabled', (v) => v as bool?),
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
        'isEnabled': 'enabled',
        'generateFor': 'generate_for',
        'devOptions': 'dev_options',
        'releaseOptions': 'release_options'
      },
    );

GlobalBuilderConfig _$GlobalBuilderConfigFromJson(Map json) => $checkedCreate(
      'GlobalBuilderConfig',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          allowedKeys: const ['options', 'dev_options', 'release_options'],
        );
        final val = GlobalBuilderConfig(
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
        'devOptions': 'dev_options',
        'releaseOptions': 'release_options'
      },
    );
