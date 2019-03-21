import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'build_target.g.dart';

abstract class BuildTarget {
  String get target;
}

abstract class DefaultBuildTarget
    implements
        BuildTarget,
        Built<DefaultBuildTarget, DefaultBuildTargetBuilder> {
  static Serializer<DefaultBuildTarget> get serializer =>
      _$defaultBuildTargetSerializer;

  factory DefaultBuildTarget([void Function(DefaultBuildTargetBuilder) b]) =
      _$DefaultBuildTarget;

  DefaultBuildTarget._();

  BuiltSet<RegExp> get blackListPatterns;

  @nullable
  OutputLocation get outputLocation;
}

abstract class OutputLocation
    implements Built<OutputLocation, OutputLocationBuilder> {
  static Serializer<OutputLocation> get serializer =>
      _$outputLocationSerializer;

  factory OutputLocation([updates(OutputLocationBuilder b)]) = _$OutputLocation;

  OutputLocation._();

  String get output;

  bool get outputSymlinks;

  bool get hoist;
}
