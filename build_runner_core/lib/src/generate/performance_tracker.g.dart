// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'performance_tracker.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BuildPerformance _$BuildPerformanceFromJson(Map<String, dynamic> json) =>
    BuildPerformance(
      (json['phases'] as List<dynamic>).map(
        (e) => BuildPhasePerformance.fromJson(e as Map<String, dynamic>),
      ),
      (json['actions'] as List<dynamic>).map(
        (e) => BuilderActionPerformance.fromJson(e as Map<String, dynamic>),
      ),
      DateTime.parse(json['startTime'] as String),
      DateTime.parse(json['stopTime'] as String),
    );

Map<String, dynamic> _$BuildPerformanceToJson(BuildPerformance instance) =>
    <String, dynamic>{
      'startTime': instance.startTime.toIso8601String(),
      'stopTime': instance.stopTime.toIso8601String(),
      'phases': instance.phases.toList(),
      'actions': instance.actions.toList(),
    };

BuildPhasePerformance _$BuildPhasePerformanceFromJson(
  Map<String, dynamic> json,
) => BuildPhasePerformance(
  (json['builderKeys'] as List<dynamic>).map((e) => e as String).toList(),
  DateTime.parse(json['startTime'] as String),
  DateTime.parse(json['stopTime'] as String),
);

Map<String, dynamic> _$BuildPhasePerformanceToJson(
  BuildPhasePerformance instance,
) => <String, dynamic>{
  'startTime': instance.startTime.toIso8601String(),
  'stopTime': instance.stopTime.toIso8601String(),
  'builderKeys': instance.builderKeys,
};

BuilderActionPerformance _$BuilderActionPerformanceFromJson(
  Map<String, dynamic> json,
) => BuilderActionPerformance(
  json['builderKey'] as String,
  _assetIdFromJson(json['primaryInput'] as String),
  (json['stages'] as List<dynamic>).map(
    (e) => BuilderActionStagePerformance.fromJson(e as Map<String, dynamic>),
  ),
  DateTime.parse(json['startTime'] as String),
  DateTime.parse(json['stopTime'] as String),
);

Map<String, dynamic> _$BuilderActionPerformanceToJson(
  BuilderActionPerformance instance,
) => <String, dynamic>{
  'startTime': instance.startTime.toIso8601String(),
  'stopTime': instance.stopTime.toIso8601String(),
  'builderKey': instance.builderKey,
  'primaryInput': _assetIdToJson(instance.primaryInput),
  'stages': instance.stages.toList(),
};

BuilderActionStagePerformance _$BuilderActionStagePerformanceFromJson(
  Map<String, dynamic> json,
) => BuilderActionStagePerformance(
  json['label'] as String,
  (json['slices'] as List<dynamic>)
      .map((e) => TimeSlice.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$BuilderActionStagePerformanceToJson(
  BuilderActionStagePerformance instance,
) => <String, dynamic>{'slices': instance.slices, 'label': instance.label};
