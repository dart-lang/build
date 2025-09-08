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

typedef PackageFilter = bool Function(PackageNode node);

/// A description of which packages need a given [Builder] or
/// [PostProcessBuilder] applied.
class BuilderApplication {
  /// Factories that create [BuildPhase]s for all [Builder]s or
  /// [PostProcessBuilder]s that should be applied.
  final List<BuildPhaseFactory> buildPhaseFactories;

  /// Determines whether a given package needs builder applied.
  final PackageFilter filter;

  /// Builder keys which, when applied to a target, will also apply this Builder
  /// even if [filter] does not match.
  final Iterable<String> appliesBuilders;

  /// A uniqe key for this builder.
  ///
  /// Ignored when null or empty.
  final String builderKey;

  /// Whether generated assets should be placed in the build cache.
  final bool hideOutput;

  const BuilderApplication(
    this.builderKey,
    this.buildPhaseFactories,
    this.filter,
    this.hideOutput,
    this.appliesBuilders,
  );
}
