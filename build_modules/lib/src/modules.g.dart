// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'modules.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Module _$ModuleFromJson(Map<String, dynamic> json) {
  return new Module(
      _assetIdFromJson(json['p'] as List),
      _assetIdsFromJson(json['s'] as List),
      _assetIdsFromJson(json['d'] as List));
}

abstract class _$ModuleSerializerMixin {
  AssetId get primarySource;
  Set<AssetId> get sources;
  Set<AssetId> get directDependencies;
  Map<String, dynamic> toJson() => <String, dynamic>{
        'p': _assetIdToJson(primarySource),
        's': _assetIdsToJson(sources),
        'd': _assetIdsToJson(directDependencies)
      };
}
