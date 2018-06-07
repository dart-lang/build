// GENERATED CODE - DO NOT MODIFY BY HAND

part of build_runner.src.generate.performance_tracker;

// **************************************************************************
// Generator: JsonSerializableGenerator
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

abstract class _$BuildPerformanceSerializerMixin {
  DateTime get startTime;
  DateTime get stopTime;
  Iterable<BuildPhasePerformance> get phases;
  Iterable<BuilderActionPerformance> get actions;
  Map<String, dynamic> toJson() => <String, dynamic>{
        'startTime': startTime?.toIso8601String(),
        'stopTime': stopTime?.toIso8601String(),
        'phases': phases?.toList(),
        'actions': actions?.toList()
      };
}

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

abstract class _$BuildPhasePerformanceSerializerMixin {
  DateTime get startTime;
  DateTime get stopTime;
  List<String> get builderKeys;
  Map<String, dynamic> toJson() => <String, dynamic>{
        'startTime': startTime?.toIso8601String(),
        'stopTime': stopTime?.toIso8601String(),
        'builderKeys': builderKeys
      };
}

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

abstract class _$BuilderActionPerformanceSerializerMixin {
  DateTime get startTime;
  DateTime get stopTime;
  String get builderKey;
  AssetId get primaryInput;
  Iterable<BuilderActionPhasePerformance> get phases;
  Map<String, dynamic> toJson() => <String, dynamic>{
        'startTime': startTime?.toIso8601String(),
        'stopTime': stopTime?.toIso8601String(),
        'builderKey': builderKey,
        'primaryInput':
            primaryInput == null ? null : _assetIdToJson(primaryInput),
        'phases': phases?.toList()
      };
}

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

abstract class _$BuilderActionPhasePerformanceSerializerMixin {
  DateTime get startTime;
  DateTime get stopTime;
  String get label;
  Map<String, dynamic> toJson() => <String, dynamic>{
        'startTime': startTime?.toIso8601String(),
        'stopTime': stopTime?.toIso8601String(),
        'label': label
      };
}
