import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'build_target.g.dart';

/// The string representation of a build target, e.g. folder path.
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

  /// A set of file path patterns to match changes against.
  ///
  /// If a change matches a pattern this target will not be built.
  BuiltSet<RegExp> get blackListPatterns;

  @nullable
  OutputLocation get outputLocation;
}

/// The location to write the build outputs.
abstract class OutputLocation
    implements Built<OutputLocation, OutputLocationBuilder> {
  static Serializer<OutputLocation> get serializer =>
      _$outputLocationSerializer;

  factory OutputLocation([updates(OutputLocationBuilder b)]) = _$OutputLocation;

  OutputLocation._();

  String get output;

  /// Whether to use symlinks for build outputs.
  bool get useSymlinks;

  /// Whether to hoist the build output.
  ///
  /// Hoisted outputs will not contain the build target folder within their
  /// path.
  ///
  /// For example hoisting the build target web:
  ///   <web>/<web-contents>
  /// Should result in:
  ///   <output-folder>/<web-contents>
  bool get hoist;
}
