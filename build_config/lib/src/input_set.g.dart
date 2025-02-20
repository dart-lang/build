// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'input_set.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InputSet _$InputSetFromJson(Map json) =>
    $checkedCreate('InputSet', json, ($checkedConvert) {
      $checkKeys(json, allowedKeys: const ['include', 'exclude']);
      final val = InputSet(
        include: $checkedConvert(
          'include',
          (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
        ),
        exclude: $checkedConvert(
          'exclude',
          (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
        ),
      );
      return val;
    });
