// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meta_module.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MetaModule _$MetaModuleFromJson(Map<String, dynamic> json) {
  return new MetaModule((json['m'] as List)
      .map((e) => new Module.fromJson(e as Map<String, dynamic>))
      .toList());
}

abstract class _$MetaModuleSerializerMixin {
  List<Module> get modules;
  Map<String, dynamic> toJson() => <String, dynamic>{'m': modules};
}
