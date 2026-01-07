// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:build_config/build_config.dart' as build_config;

import 'builder_application.dart';

/// Apply [builder] to the root package.
///
/// Creates a `BuilderApplication` which corresponds to an empty builder key so
/// that no other `build.yaml` based configuration will apply.
BuilderDefinition applyToRoot({
  bool isOptional = false,
  bool hideOutput = false,
  build_config.InputSet generateFor = const build_config.InputSet(),
}) => _forBuilder(
  '',
  '',
  build_config.AutoApply.rootPackage,
  isOptional: isOptional,
  hideOutput: hideOutput,
  defaultGenerateFor: generateFor,
);

/// Apply the builder with [builderKey] to the packages matching [autoApply].
///
/// If the builder should only run on a subset of files within a target pass
/// globs to [defaultGenerateFor]. This can be overridden by any target which
/// configured the builder manually.
///
/// If [isOptional] is true the builder will only run if one of its outputs is
/// read by a later builder, or is used as a primary input to a later builder.
/// If no build actions read the output of an optional action, then it will
/// never run.
///
/// Any existing Builders which match a key in [appliesBuilders] will
/// automatically be applied to any target which runs this Builder, whether
/// because it matches [autoApply] or because it was enabled manually.
BuilderDefinition apply(
  String builderPackage,
  String builderKey,
  build_config.AutoApply autoApply, {
  bool isOptional = false,
  bool hideOutput = true,
  build_config.InputSet defaultGenerateFor = const build_config.InputSet(),
  BuilderOptions defaultOptions = BuilderOptions.empty,
  BuilderOptions? defaultDevOptions,
  BuilderOptions? defaultReleaseOptions,
  Iterable<String> appliesBuilders = const [],
}) => _forBuilder(
  builderPackage,
  builderKey,
  autoApply,
  isOptional: isOptional,
  hideOutput: hideOutput,
  defaultGenerateFor: defaultGenerateFor,
  defaultOptions: defaultOptions,
  defaultDevOptions: defaultDevOptions,
  defaultReleaseOptions: defaultReleaseOptions,
  appliesBuilders: appliesBuilders,
);

/// Same as [apply] except it takes [PostProcessBuilderFactory]s.
///
/// Does not provide options for `isOptional` or `hideOutput` because they
/// aren't configurable for these types of builders. They are never optional and
/// always hidden.
BuilderDefinition applyPostProcess(
  String builderPackage,
  String builderKey, {
  build_config.InputSet defaultGenerateFor = const build_config.InputSet(),
  BuilderOptions defaultOptions = BuilderOptions.empty,
  BuilderOptions? defaultDevOptions,
  BuilderOptions? defaultReleaseOptions,
}) => _forPostProcessBuilder(
  builderPackage,
  builderKey,
  defaultGenerateFor: defaultGenerateFor,
  defaultOptions: defaultOptions,
  defaultDevOptions: defaultDevOptions,
  defaultReleaseOptions: defaultReleaseOptions,
);

BuilderDefinition _forBuilder(
  String builderPackage,
  String key,
  build_config.AutoApply autoApply, {
  bool isOptional = false,
  bool hideOutput = true,
  build_config.InputSet defaultGenerateFor = const build_config.InputSet(),
  BuilderOptions defaultOptions = BuilderOptions.empty,
  BuilderOptions? defaultDevOptions,
  BuilderOptions? defaultReleaseOptions,
  Iterable<String> appliesBuilders = const [],
}) {
  return BuilderDefinition(
    builderPackage: builderPackage,
    builderKey: key,
    autoApply: autoApply,
    hideOutput: hideOutput,
    isOptional: isOptional,
    appliesBuilders: appliesBuilders,
  );
}

/// Note that these builder applications each create their own phase, but they
/// will all eventually be merged into a single phase.
BuilderDefinition _forPostProcessBuilder(
  String builderPackage,
  String builderKey, {
  build_config.InputSet defaultGenerateFor = const build_config.InputSet(),
  BuilderOptions defaultOptions = BuilderOptions.empty,
  BuilderOptions? defaultDevOptions,
  BuilderOptions? defaultReleaseOptions,
}) {
  return BuilderDefinition(
    builderPackage: builderPackage,
    builderKey: builderKey,
    autoApply: AutoApply.none,
    hideOutput: true,
    isOptional: false,
    appliesBuilders: [],
  );
}
