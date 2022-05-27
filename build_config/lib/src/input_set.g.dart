// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'input_set.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InputSet _$InputSetFromJson(Map json) => $checkedCreate(
      'InputSet',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          allowedKeys: const ['include_defaults', 'include', 'exclude'],
        );
        final val = InputSet(
          include: $checkedConvert('include',
              (v) => (v as List<dynamic>?)?.map((e) => e as String).toList()),
          exclude: $checkedConvert('exclude',
              (v) => (v as List<dynamic>?)?.map((e) => e as String).toList()),
          includeDefaults:
              $checkedConvert('include_defaults', (v) => v as bool? ?? false),
        );
        return val;
      },
      fieldKeyMap: const {'includeDefaults': 'include_defaults'},
    );
