// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:build_config/build_config.dart';
import 'package:collection/collection.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

import 'input_matcher.dart';

/// A "phase" in the build graph, which represents running a one or more
/// builders on a set of sources.
abstract class BuildPhase {
  /// Whether to run lazily when an output is read.
  ///
  /// An optional build action will only run if one of its outputs is read by
  /// a later [Builder], or is used as a primary input to a later [Builder].
  ///
  /// If no build actions read the output of an optional action, then it will
  /// never run.
  bool get isOptional;

  /// Whether generated assets should be placed in the build cache.
  ///
  /// When this is `false` the Builder may not run on any package other than
  /// the root.
  bool get hideOutput;

  /// The identity of this action in terms of a build graph. If the identity of
  /// any action changes the build will be invalidated.
  ///
  /// This should take into account everything except for the builderOptions,
  /// which are tracked separately via a `BuilderOptionsNode` which supports
  /// more fine grained invalidation.
  int get identity;

  factory BuildPhase.fromJson(Map<String, dynamic> json) {
    // if (json.containsKey('builderActions')) {
    //   return new PostBuildPhase.fromJson(json);
    // } else {
    //   return new InBuildPhase.fromJson(json);
    // }
    return null;
  }
}

/// An "action" in the build graph which represents running a single builder
/// on a set of sources.
abstract class BuildAction {
  /// Either a [Builder] or a [PostProcessBuilder].
  dynamic get builder;
  String get builderLabel;
  BuilderOptions get builderOptions;
  InputMatcher get generateFor;
  String get package;
  InputMatcher get targetSources;
}

/// A [BuildPhase] that uses a single [Builder] to generate files.
@JsonSerializable()
class InBuildPhase extends Object implements BuildAction, BuildPhase {
  @override
  @JsonKey(ignore: true)
  final Builder builder;
  @override
  final String builderLabel;
  @override
  @JsonKey(toJson: _builderOptionsToJson, fromJson: _builderOptionsFromJson)
  final BuilderOptions builderOptions;
  @override
  @JsonKey(fromJson: _inputMatcherFromJson, toJson: _inputMatcherToJson)
  final InputMatcher generateFor;
  @override
  final String package;
  @override
  @JsonKey(fromJson: _inputMatcherFromJson, toJson: _inputMatcherToJson)
  final InputMatcher targetSources;

  @override
  final bool isOptional;
  @override
  final bool hideOutput;

  InBuildPhase._(this.package, this.builder, this.builderOptions,
      {@required this.targetSources,
      @required this.generateFor,
      @required this.builderLabel,
      bool isOptional,
      bool hideOutput})
      : this.isOptional = isOptional ?? false,
        this.hideOutput = hideOutput ?? false;

  /// Creates an [BuildPhase] for a normal [Builder].
  ///
  /// The build target is defined by [package] as well as [targetSources]. By
  /// default all sources in the target are used as primary inputs to the
  /// builder, but it can be further filtered with [generateFor].
  ///
  /// [isOptional] specifies that a Builder may not be run unless some other
  /// Builder in a later phase attempts to read one of the potential outputs.
  ///
  /// [hideOutput] specifies that the generated asses should be placed in the
  /// build cache rather than the source tree.
  factory InBuildPhase(
    Builder builder,
    String package, {
    String builderKey,
    InputSet targetSources,
    InputSet generateFor,
    BuilderOptions builderOptions,
    bool isOptional,
    bool hideOutput,
  }) {
    var targetSourceMatcher =
        new InputMatcher(targetSources ?? const InputSet());
    var generateForMatcher = new InputMatcher(generateFor ?? const InputSet());
    builderOptions ??= const BuilderOptions(const {});
    return new InBuildPhase._(package, builder, builderOptions,
        targetSources: targetSourceMatcher,
        generateFor: generateForMatcher,
        builderLabel: builderKey == null || builderKey.isEmpty
            ? _builderLabel(builder)
            : _simpleBuilderKey(builderKey),
        isOptional: isOptional,
        hideOutput: hideOutput);
  }

  // factory InBuildPhase.fromJson(Map<String, dynamic> json) =>
  //     _$InBuildPhaseFromJson(json);

  @override
  String toString() {
    final settings = <String>[];
    if (isOptional) settings.add('optional');
    if (hideOutput) settings.add('hidden');
    var result = '$builderLabel on $targetSources in $package';
    if (settings.isNotEmpty) result += ' $settings';
    return result;
  }

  @override
  int get identity => _deepEquals.hash([
        builderLabel,
        builder.buildExtensions,
        package,
        targetSources,
        generateFor,
        isOptional,
        hideOutput
      ]);
}

/// A [BuildPhase] that can run multiple [PostBuildAction]s to
/// generate files.
///
/// There should only be one of these per build, and it should be the final
/// phase.
@JsonSerializable()
class PostBuildPhase extends Object implements BuildPhase {
  final List<PostBuildAction> builderActions;

  @override
  bool get hideOutput => true;
  @override
  bool get isOptional => false;

  PostBuildPhase(this.builderActions);

  // factory PostBuildPhase.fromJson(Map<String, dynamic> json) =>
  //     _$PostBuildPhaseFromJson(json);

  @override
  String toString() =>
      '${builderActions.map((a) => a.builderLabel).join(', ')}';

  @override
  int get identity =>
      _deepEquals.hash(builderActions.map<dynamic>((b) => b.identity).toList()
        ..addAll([
          isOptional,
          hideOutput,
        ]));
}

/// Part of a larger [PostBuildPhase], applies a single
/// [PostProcessBuilder] to a single [package] with some additional options.
@JsonSerializable()
class PostBuildAction implements BuildAction {
  @override
  @JsonKey(ignore: true)
  final PostProcessBuilder builder;
  @override
  final String builderLabel;
  @override
  final BuilderOptions builderOptions;
  @override
  @JsonKey(fromJson: _inputMatcherFromJson, toJson: _inputMatcherToJson)
  final InputMatcher generateFor;
  @override
  final String package;
  @override
  @JsonKey(fromJson: _inputMatcherFromJson, toJson: _inputMatcherToJson)
  final InputMatcher targetSources;

  PostBuildAction(this.builder, this.package,
      {String builderKey,
      @required BuilderOptions builderOptions,
      @required InputSet targetSources,
      @required InputSet generateFor})
      : builderLabel = builderKey == null || builderKey.isEmpty
            ? _builderLabel(builder)
            : _simpleBuilderKey(builderKey),
        builderOptions = builderOptions ?? const BuilderOptions(const {}),
        targetSources = new InputMatcher(targetSources ?? const InputSet()),
        generateFor = new InputMatcher(generateFor ?? const InputSet());

  // factory PostBuildAction.fromJson(Map<String, dynamic> json) =>
  //     _$PostBuildActionFromJson(json);

  int get identity => _deepEquals.hash([
        builderLabel,
        builder.inputExtensions.toList(),
        generateFor,
        package,
        targetSources,
      ]);
}

/// If we have no key find a human friendly name for the Builder.
String _builderLabel(Object builder) {
  var label = '$builder';
  if (label.startsWith('Instance of \'')) {
    label = label.substring(13, label.length - 1);
  }
  return label;
}

/// Change "angular|angular" to "angular".
String _simpleBuilderKey(String builderKey) {
  if (!builderKey.contains('|')) return builderKey;
  var parts = builderKey.split('|');
  if (parts[0] == parts[1]) return parts[0];
  return builderKey;
}

final _deepEquals = const DeepCollectionEquality();

BuilderOptions _builderOptionsFromJson(Map<String, dynamic> json) =>
    new BuilderOptions(json);
Map<String, dynamic> _builderOptionsToJson(BuilderOptions options) =>
    options.config;

InputMatcher _inputMatcherFromJson(Map<String, List> json) =>
    new InputMatcher(new InputSet(
        include: json['include'].cast(), exclude: json['exclude'].cast()));

Map<String, List<String>> _inputMatcherToJson(InputMatcher matcher) => {
      'include': matcher.includeGlobs.map((g) => g.pattern).toList(),
      'exclude': matcher.excludeGlobs.map((g) => g.pattern).toList()
    };
