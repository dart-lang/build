// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'platform.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Platforms _$PlatformsFromJson(Map<String, dynamic> json) {
  return Platforms((json['platforms'] as Map<String, dynamic>)?.map((k, e) =>
      MapEntry(
          k, e == null ? null : Platform.fromJson(e as Map<String, dynamic>))));
}

Platform _$PlatformFromJson(Map<String, dynamic> json) {
  return Platform(
      (json['libraries'] as Map<String, dynamic>)?.map((k, e) => MapEntry(k,
          e == null ? null : CoreLibrary.fromJson(e as Map<String, dynamic>))),
      json['name'] as String);
}

CoreLibrary _$CoreLibraryFromJson(Map<String, dynamic> json) {
  $checkKeys(json, requiredKeys: ['uri']);
  return CoreLibrary(
      json['patches'] == null ? null : _patchesFromJson(json['patches']),
      json['uri'] as String,
      json['supported'] as bool ?? true);
}
