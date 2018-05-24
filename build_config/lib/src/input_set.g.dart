// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'input_set.dart';

// **************************************************************************
// Generator: JsonSerializableGenerator
// **************************************************************************

InputSet _$InputSetFromJson(Map json) => $checkedNew(
    'InputSet',
    json,
    () => new InputSet(
        include: $checkedConvert(json, 'include',
            (v) => (v as List)?.map((e) => e as String)?.toList()),
        exclude: $checkedConvert(json, 'exclude',
            (v) => (v as List)?.map((e) => e as String)?.toList())));
