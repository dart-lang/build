// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build_config/build_config.dart' as build_config;
import 'package:built_collection/built_collection.dart';
import 'package:meta/meta.dart';

import 'package_graph.dart';

/// A builder definition read from `build.yaml` using
/// [build_config.BuilderDefinition] or
/// [build_config.PostProcessBuilderDefinition].
class BuilderDefinition {
  final bool isPostProcessBuilder;

  /// The package the builder is in.
  final String package;

  /// The builder key in the form `package:name`.
  final String key;

  /// Determines which packages a builder is automatically applied to.
  final AutoApply autoApply;

  /// Builder keys which, when applied to a target, will also apply this Builder
  /// even if [autoApply] does not match.
  final BuiltList<String> appliesBuilders;

  /// Whether generated assets should be placed in the build cache.
  final bool hideOutput;

  /// Whether the builder is skipped if nothing uses its output.
  final bool isOptional;

  @visibleForTesting
  BuilderDefinition(
    this.key, {
    this.isPostProcessBuilder = false,
    String? package,
    this.autoApply = AutoApply.rootPackage,
    Iterable<String> appliesBuilders = const [],
    this.hideOutput = false,
    this.isOptional = false,
  }) : appliesBuilders = appliesBuilders.toBuiltList(),
       package = package ?? (key.contains(':') ? key.split(':').first : '');

  BuilderDefinition.fromConfig(build_config.BuilderDefinition builderDefinition)
    : isPostProcessBuilder = false,
      package = builderDefinition.package,
      key = builderDefinition.key,
      autoApply = builderDefinition.autoApply,
      appliesBuilders = builderDefinition.appliesBuilders.build(),
      hideOutput = builderDefinition.buildTo == build_config.BuildTo.cache,
      isOptional = builderDefinition.isOptional;

  BuilderDefinition.fromPostProcessConfig(
    build_config.PostProcessBuilderDefinition builderDefinition,
  ) : isPostProcessBuilder = true,
      package = builderDefinition.package,
      key = builderDefinition.key,
      autoApply = build_config.AutoApply.allPackages,
      appliesBuilders = BuiltList(),
      hideOutput = true,
      isOptional = false;

  /// Whether this builder application is auto applied to [package].
  bool autoAppliesTo(PackageNode package) {
    switch (autoApply) {
      case AutoApply.none:
        return false;
      case AutoApply.allPackages:
        return true;
      case AutoApply.rootPackage:
        return package.isRoot;
      case AutoApply.dependents:
        return package.dependencies.any((p) => p.name == this.package);
    }
  }
}

typedef AutoApply = build_config.AutoApply;
