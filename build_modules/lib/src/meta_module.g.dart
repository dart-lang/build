// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meta_module.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MetaModule _$MetaModuleFromJson(Map<String, dynamic> json) {
  return MetaModule(
    (json['m'] as List)
        .map((e) => Module.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

Map<String, dynamic> _$MetaModuleToJson(MetaModule instance) =>
    <String, dynamic>{
      'm': instance.modules,
    };
