// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'modules.dart';

// **************************************************************************
// Generator: JsonSerializableGenerator
// **************************************************************************

Module _$ModuleFromJson(Map<String, dynamic> json) => new Module(
    new AssetId.deserialize(json['p'] as List),
    (json['s'] as List).map((e) => new AssetId.deserialize(e as List)),
    (json['d'] as List).map((e) => new AssetId.deserialize(e as List)));

abstract class _$ModuleSerializerMixin {
  AssetId get primarySource;
  Set<AssetId> get sources;
  Set<AssetId> get directDependencies;
  Map<String, dynamic> toJson() => <String, dynamic>{
        'p': primarySource.serialize(),
        's': sources.map((e) => e.serialize()).toList(),
        'd': directDependencies.map((e) => e.serialize()).toList()
      };
}
