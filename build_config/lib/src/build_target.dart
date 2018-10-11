// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:json_annotation/json_annotation.dart';

import 'builder_definition.dart';
import 'common.dart';
import 'expandos.dart';
import 'input_set.dart';
import 'key_normalization.dart';

part 'build_target.g.dart';

@JsonSerializable(createToJson: false, disallowUnrecognizedKeys: true)
class BuildTarget {
  /// A map from builder key to the configuration used for this target.
  ///
  /// Builder keys are in the format `"$package|$builder"`. This does not
  /// represent the full set of builders that are applied to the target, only
  /// those which have configuration customized against the default.
  final Map<String, TargetBuilderConfig> builders;

  final List<String> dependencies;

  final InputSet sources;

  /// A unique key for this target in `'$package:$target'` format.
  String get key => builderKeyExpando[this];

  String get package => packageExpando[this];

  BuildTarget({
    InputSet sources,
    Iterable<String> dependencies,
    Map<String, TargetBuilderConfig> builders,
  })  : dependencies = (dependencies ?? currentPackageDefaultDependencies)
            .map((d) => normalizeTargetKeyUsage(d, currentPackage))
            .toList(),
        builders = (builders ?? const {}).map((key, config) =>
            MapEntry(normalizeBuilderKeyUsage(key, currentPackage), config)),
        sources = sources ?? InputSet.anything;

  factory BuildTarget.fromJson(Map json) => _$BuildTargetFromJson(json);

  @override
  String toString() => {
        'package': package,
        'sources': sources,
        'dependencies': dependencies,
        'builders': builders,
      }.toString();
}

/// The configuration a particular [BuildTarget] applies to a Builder.
///
/// Build targets may have builders applied automatically based on
/// [BuilderDefinition.autoApply] and may override with more specific
/// configuration.
@JsonSerializable(createToJson: false, disallowUnrecognizedKeys: true)
class TargetBuilderConfig {
  /// Overrides the setting of whether the Builder would run on this target.
  ///
  /// Builders may run on this target by default based on the `apply_to`
  /// argument, set to `false` to disable a Builder which would otherwise run.
  ///
  /// By default including a config for a Builder enables that builder.
  @JsonKey(name: 'enabled')
  final bool isEnabled;

  /// Sources to use as inputs for this Builder in glob format.
  ///
  /// This is always a subset of the `include` argument in the containing
  /// [BuildTarget]. May be `null` in which cases it will be all the sources in
  /// the target.
  @JsonKey(name: 'generate_for')
  final InputSet generateFor;

  /// The options to pass to the `BuilderFactory` when constructing this
  /// builder.
  ///
  /// The `options` key in the configuration.
  ///
  /// Individual keys may be overridden by either [devOptions] or
  /// [releaseOptions].
  @JsonKey(fromJson: builderOptionsFromJson)
  final BuilderOptions options;

  /// Overrides for [options] in dev mode.
  @JsonKey(name: 'dev_options', fromJson: builderOptionsFromJson)
  final BuilderOptions devOptions;

  /// Overrides for [options] in release mode.
  @JsonKey(name: 'release_options', fromJson: builderOptionsFromJson)
  final BuilderOptions releaseOptions;

  TargetBuilderConfig({
    bool isEnabled,
    this.generateFor,
    BuilderOptions options,
    BuilderOptions devOptions,
    BuilderOptions releaseOptions,
  })  : isEnabled = isEnabled ?? true,
        options = options ?? BuilderOptions.empty,
        devOptions = devOptions ?? BuilderOptions.empty,
        releaseOptions = releaseOptions ?? BuilderOptions.empty;

  factory TargetBuilderConfig.fromJson(Map json) =>
      _$TargetBuilderConfigFromJson(json);

  @override
  String toString() => {
        'isEnabled': isEnabled,
        'generateFor': generateFor,
        'options': options.config,
        'devOptions': devOptions.config,
        'releaseOptions': releaseOptions.config,
      }.toString();
}

/// The configuration for a Builder applied globally.
@JsonSerializable(createToJson: false, disallowUnrecognizedKeys: true)
class GlobalBuilderConfig {
  /// The options to pass to the `BuilderFactory` when constructing this
  /// builder.
  ///
  /// The `options` key in the configuration.
  ///
  /// Individual keys may be overridden by either [devOptions] or
  /// [releaseOptions].
  @JsonKey(fromJson: builderOptionsFromJson)
  final BuilderOptions options;

  /// Overrides for [options] in dev mode.
  @JsonKey(name: 'dev_options', fromJson: builderOptionsFromJson)
  final BuilderOptions devOptions;

  /// Overrides for [options] in release mode.
  @JsonKey(name: 'release_options', fromJson: builderOptionsFromJson)
  final BuilderOptions releaseOptions;

  GlobalBuilderConfig({
    BuilderOptions options,
    BuilderOptions devOptions,
    BuilderOptions releaseOptions,
  })  : options = options ?? BuilderOptions.empty,
        devOptions = devOptions ?? BuilderOptions.empty,
        releaseOptions = releaseOptions ?? BuilderOptions.empty;

  factory GlobalBuilderConfig.fromJson(Map json) =>
      _$GlobalBuilderConfigFromJson(json);

  @override
  String toString() => {
        'options': options.config,
        'devOptions': devOptions.config,
        'releaseOptions': releaseOptions.config,
      }.toString();
}
