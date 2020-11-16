// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'modules.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Module _$ModuleFromJson(Map<String, dynamic> json) {
  return Module(
    const _AssetIdConverter().fromJson(json['p'] as List),
    (json['s'] as List)
        .map((e) => const _AssetIdConverter().fromJson(e as List)),
    (json['d'] as List)
        .map((e) => const _AssetIdConverter().fromJson(e as List)),
    const _DartPlatformConverter().fromJson(json['pf'] as String),
    json['is'] as bool,
    isMissing: json['m'] as bool ?? false,
  );
}

Map<String, dynamic> _$ModuleToJson(Module instance) => <String, dynamic>{
      'p': const _AssetIdConverter().toJson(instance.primarySource),
      's': _toJsonAssetIds(instance.sources),
      'd': _toJsonAssetIds(instance.directDependencies),
      'm': instance.isMissing,
      'is': instance.isSupported,
      'pf': const _DartPlatformConverter().toJson(instance.platform),
    };
