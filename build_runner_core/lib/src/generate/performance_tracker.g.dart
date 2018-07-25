// GENERATED CODE - DO NOT MODIFY BY HAND

part of build_runner.src.generate.performance_tracker;

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BuildPerformance _$BuildPerformanceFromJson(Map<String, dynamic> json) {
  return new BuildPerformance(
      (json['phases'] as List)?.map((e) => e == null
          ? null
          : new BuildPhasePerformance.fromJson(e as Map<String, dynamic>)),
      (json['actions'] as List)?.map((e) => e == null
          ? null
          : new BuilderActionPerformance.fromJson(e as Map<String, dynamic>)),
      json['startTime'] == null
          ? null
          : DateTime.parse(json['startTime'] as String),
      json['stopTime'] == null
          ? null
          : DateTime.parse(json['stopTime'] as String));
}

Map<String, dynamic> _$BuildPerformanceToJson(BuildPerformance instance) =>
    <String, dynamic>{
      'startTime': instance.startTime?.toIso8601String(),
      'stopTime': instance.stopTime?.toIso8601String(),
      'phases': instance.phases?.toList(),
      'actions': instance.actions?.toList()
    };

BuildPhasePerformance _$BuildPhasePerformanceFromJson(
    Map<String, dynamic> json) {
  return new BuildPhasePerformance(
      (json['builderKeys'] as List)?.map((e) => e as String)?.toList(),
      json['startTime'] == null
          ? null
          : DateTime.parse(json['startTime'] as String),
      json['stopTime'] == null
          ? null
          : DateTime.parse(json['stopTime'] as String));
}

Map<String, dynamic> _$BuildPhasePerformanceToJson(
        BuildPhasePerformance instance) =>
    <String, dynamic>{
      'startTime': instance.startTime?.toIso8601String(),
      'stopTime': instance.stopTime?.toIso8601String(),
      'builderKeys': instance.builderKeys
    };

BuilderActionPerformance _$BuilderActionPerformanceFromJson(
    Map<String, dynamic> json) {
  return new BuilderActionPerformance(
      json['builderKey'] as String,
      json['primaryInput'] == null
          ? null
          : _assetIdFromJson(json['primaryInput'] as String),
      (json['phases'] as List)?.map((e) => e == null
          ? null
          : new BuilderActionPhasePerformance.fromJson(
              e as Map<String, dynamic>)),
      json['startTime'] == null
          ? null
          : DateTime.parse(json['startTime'] as String),
      json['stopTime'] == null
          ? null
          : DateTime.parse(json['stopTime'] as String));
}

Map<String, dynamic> _$BuilderActionPerformanceToJson(
        BuilderActionPerformance instance) =>
    <String, dynamic>{
      'startTime': instance.startTime?.toIso8601String(),
      'stopTime': instance.stopTime?.toIso8601String(),
      'builderKey': instance.builderKey,
      'primaryInput': instance.primaryInput == null
          ? null
          : _assetIdToJson(instance.primaryInput),
      'phases': instance.phases?.toList()
    };

BuilderActionPhasePerformance _$BuilderActionPhasePerformanceFromJson(
    Map<String, dynamic> json) {
  return new BuilderActionPhasePerformance(
      json['label'] as String,
      json['startTime'] == null
          ? null
          : DateTime.parse(json['startTime'] as String),
      json['stopTime'] == null
          ? null
          : DateTime.parse(json['stopTime'] as String));
}

Map<String, dynamic> _$BuilderActionPhasePerformanceToJson(
        BuilderActionPhasePerformance instance) =>
    <String, dynamic>{
      'startTime': instance.startTime?.toIso8601String(),
      'stopTime': instance.stopTime?.toIso8601String(),
      'label': instance.label
    };
