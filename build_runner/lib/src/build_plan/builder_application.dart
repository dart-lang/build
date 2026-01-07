// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build_config/build_config.dart' as build_config;

import 'package_graph.dart';

/// A [build_config.BuilderDefinition] or
/// [build_config.PostProcessBuilderDefinition].
class BuilderDefinition {
  final build_config.BuilderDefinition? builderDefinition;
  final build_config.PostProcessBuilderDefinition? postProcessBuilderDefinition;

  BuilderDefinition(this.builderDefinition)
    : postProcessBuilderDefinition = null;

  BuilderDefinition.postProcess(this.postProcessBuilderDefinition)
    : builderDefinition = null;

  bool get isPostProcessBuilder => postProcessBuilderDefinition != null;

  /// The package the builder is in.
  String get builderPackage =>
      isPostProcessBuilder
          ? postProcessBuilderDefinition!.package
          : builderDefinition!.package;

  /// The builder key in the form `package:name`.
  String get builderKey =>
      isPostProcessBuilder
          ? postProcessBuilderDefinition!.key
          : builderDefinition!.key;

  /// Determines which packages a builder is automatically applied to.
  build_config.AutoApply get autoApply =>
      isPostProcessBuilder
          ? build_config.AutoApply.allPackages
          : builderDefinition!.autoApply;

  /// Builder keys which, when applied to a target, will also apply this Builder
  /// even if [autoApply] does not match.
  Iterable<String> get appliesBuilders =>
      isPostProcessBuilder ? [] : builderDefinition!.appliesBuilders;

  /// Whether generated assets should be placed in the build cache.
  bool get hideOutput =>
      isPostProcessBuilder
          ? true
          : builderDefinition!.buildTo == build_config.BuildTo.cache;

  /// Whether the builder is skipped if nothing uses its output.
  bool get isOptional =>
      isPostProcessBuilder ? false : builderDefinition!.isOptional;

  /// Whether this builder application is auto applied to [package].
  bool autoAppliesTo(PackageNode package) {
    switch (autoApply) {
      case build_config.AutoApply.none:
        return false;
      case build_config.AutoApply.allPackages:
        return true;
      case build_config.AutoApply.rootPackage:
        return package.isRoot;
      case build_config.AutoApply.dependents:
        return package.dependencies.any((p) => p.name == builderPackage);
    }
  }
}
