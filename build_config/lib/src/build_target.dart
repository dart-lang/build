// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:json_annotation/json_annotation.dart';

import 'builder_definition.dart';
import 'common.dart';
import 'expandos.dart';
import 'input_set.dart';
import 'key_normalization.dart';

part 'build_target.g.dart';

@JsonSerializable()
class BuildTarget {
  final bool autoApplyBuilders;

  /// A map from builder key to the configuration used for this target.
  ///
  /// Builder keys are in the format `"$package|$builder"`. This does not
  /// represent the full set of builders that are applied to the target, only
  /// those which have configuration customized against the default.
  final Map<String, TargetBuilderConfig> builders;

  final List<String> dependencies;

  final InputSet sources;

  /// A unique key for this target in `'$package:$target'` format.
  String get key => builderKeyExpando[this]!;

  String get package => packageExpando[this]!;

  BuildTarget({
    bool? autoApplyBuilders,
    InputSet? sources,
    Iterable<String>? dependencies,
    Map<String, TargetBuilderConfig>? builders,
  }) : autoApplyBuilders = autoApplyBuilders ?? true,
       dependencies =
           (dependencies ?? currentPackageDefaultDependencies)
               .map((d) => normalizeTargetKeyUsage(d, currentPackage))
               .toList(),
       builders = (builders ?? const {}).map(
         (key, config) =>
             MapEntry(normalizeBuilderKeyUsage(key, currentPackage), config),
       ),
       sources = sources ?? InputSet.anything;

  factory BuildTarget.fromJson(Map json) {
    ArgumentError.checkNotNull(json);
    return _$BuildTargetFromJson(json);
  }

  @override
  String toString() =>
      {
        'package': package,
        'sources': sources,
        'dependencies': dependencies,
        'builders': builders,
        'autoApplyBuilders': autoApplyBuilders,
      }.toString();
}

/// The configuration a particular [BuildTarget] applies to a Builder.
///
/// Build targets may have builders applied automatically based on
/// [BuilderDefinition.autoApply] and may override with more specific
/// configuration.
@JsonSerializable()
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
  final InputSet? generateFor;

  /// The options to pass to the `BuilderFactory` when constructing this
  /// builder.
  ///
  /// The `options` key in the configuration.
  ///
  /// Individual keys may be overridden by either [devOptions] or
  /// [releaseOptions].
  final Map<String, dynamic> options;

  /// Overrides for [options] in dev mode.
  final Map<String, dynamic> devOptions;

  /// Overrides for [options] in release mode.
  final Map<String, dynamic> releaseOptions;

  TargetBuilderConfig({
    bool? isEnabled,
    this.generateFor,
    Map<String, dynamic>? options,
    Map<String, dynamic>? devOptions,
    Map<String, dynamic>? releaseOptions,
  }) : isEnabled = isEnabled ?? true,
       options = options ?? const {},
       devOptions = devOptions ?? const {},
       releaseOptions = releaseOptions ?? const {};

  factory TargetBuilderConfig.fromJson(Map json) {
    ArgumentError.checkNotNull(json);
    return _$TargetBuilderConfigFromJson(json);
  }

  @override
  String toString() =>
      {
        'isEnabled': isEnabled,
        'generateFor': generateFor,
        'options': options,
        'devOptions': devOptions,
        'releaseOptions': releaseOptions,
      }.toString();
}

/// The configuration for a Builder applied globally.
@JsonSerializable()
class GlobalBuilderConfig {
  /// The options to pass to the `BuilderFactory` when constructing this
  /// builder.
  ///
  /// The `options` key in the configuration.
  ///
  /// Individual keys may be overridden by either [devOptions] or
  /// [releaseOptions].
  final Map<String, dynamic> options;

  /// Overrides for [options] in dev mode.
  final Map<String, dynamic> devOptions;

  /// Overrides for [options] in release mode.
  final Map<String, dynamic> releaseOptions;

  /// Builder keys in `$package:$builder` format which should only be run after
  /// this Builder.
  ///
  /// This allows the user to configure the ordering of particular builders as
  /// necessary, but it is a global option.
  ///
  /// This config is merged with the `runsBefore` configuration of the builder
  /// definition, and does not overwrite it.
  final List<String> runsBefore;

  GlobalBuilderConfig({
    Map<String, dynamic>? options,
    Map<String, dynamic>? devOptions,
    Map<String, dynamic>? releaseOptions,
    List<String>? runsBefore,
  }) : options = options ?? const {},
       devOptions = devOptions ?? const {},
       releaseOptions = releaseOptions ?? const {},
       runsBefore =
           runsBefore
               ?.map(
                 (builder) => normalizeBuilderKeyUsage(builder, currentPackage),
               )
               .toList() ??
           const [];

  factory GlobalBuilderConfig.fromJson(Map json) {
    ArgumentError.checkNotNull(json);
    return _$GlobalBuilderConfigFromJson(json);
  }

  @override
  String toString() =>
      {
        'options': options,
        'devOptions': devOptions,
        'releaseOptions': releaseOptions,
        'runsBefore': runsBefore,
      }.toString();
}
