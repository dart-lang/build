// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:build_config/build_config.dart';

import 'package_graph.dart';
import 'phase.dart';

typedef BuildPhaseFactory =
    BuildPhase Function(
      PackageNode package,
      BuilderOptions options,
      InputSet targetSources,
      InputSet? generateFor,
      bool isReleaseBuild,
    );

/// A description of which packages need a given [Builder] or
/// [PostProcessBuilder] applied.
class BuilderApplication {
  /// Factories that create [BuildPhase]s for all [Builder]s or
  /// [PostProcessBuilder]s that should be applied.
  final List<BuildPhaseFactory> buildPhaseFactories;

  /// Determines which packages a builder is automatically applied to.
  final AutoApply autoApply;

  /// Builder keys which, when applied to a target, will also apply this Builder
  /// even if [autoApply] does not match.
  final Iterable<String> appliesBuilders;

  /// The package the builder is in.
  final String builderPackage;

  /// A uniqe key for this builder.
  ///
  /// Ignored when null or empty.
  final String builderKey;

  /// Whether generated assets should be placed in the build cache.
  final bool hideOutput;

  BuilderApplication(
    this.builderPackage,
    this.builderKey,
    this.buildPhaseFactories,
    this.autoApply,
    this.hideOutput,
    this.appliesBuilders,
  );

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
        return package.dependencies.any((p) => p.name == builderPackage);
    }
  }
}
