// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'modules.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Module _$ModuleFromJson(Map<String, dynamic> json) {
  return Module(
      _assetIdFromJson(json['p'] as List),
      _assetIdsFromJson(json['s'] as List),
      _assetIdsFromJson(json['d'] as List),
      json['pf'] as String,
      isMissing: json['m'] as bool ?? false);
}

Map<String, dynamic> _$ModuleToJson(Module instance) => <String, dynamic>{
      'p': _assetIdToJson(instance.primarySource),
      's': _assetIdsToJson(instance.sources),
      'd': _assetIdsToJson(instance.directDependencies),
      'm': instance.isMissing,
      'pf': instance.platform
    };
