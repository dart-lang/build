// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:built_collection/built_collection.dart';

import '../build_plan/build_configs.dart';
import '../build_plan/build_directory.dart';
import '../build_plan/build_filter.dart';
import '../build_plan/phase.dart';

/// Returns whether or not [id] should be built based upon [buildDirs],
/// [phase], [buildConfigs], and optional [buildFilters].
///
/// The logic for this is as follows:
///
/// - If any [buildFilters] are supplied, then this only returns `true` if [id]
///   explicitly matches one of the filters.
/// - If no [buildFilters] are supplied, then the old behavior applies - all
///   build to source builders and all public assets (according to
///   [BuildConfigs.isPublicAsset]) are always built.
/// - Regardless of the [buildFilters] setting, if [buildDirs] is supplied then
///   `id.path` must start with one of the specified directory names.
bool shouldBuildForDirs(
  AssetId id, {
  required BuiltSet<BuildDirectory> buildDirs,
  required BuildPhase phase,
  required BuildConfigs buildConfigs,
  BuiltSet<BuildFilter>? buildFilters,
}) {
  // Empty paths means "build everything".
  final paths = BuildDirectory.buildPaths(buildDirs);
  buildFilters ??= BuiltSet();
  if (buildFilters.isEmpty) {
    // Build asset if: It's built to source, it's public or if it's matched by
    // a build directory.
    return !phase.hideOutput ||
        paths.isEmpty ||
        paths.any(id.path.startsWith) ||
        buildConfigs.isPublicAsset(id);
  } else {
    // Don't build assets not matched by build filters
    if (!buildFilters.any((f) => f.matches(id))) {
      return false;
    }

    // In filtered assets, build the public ones or those inside a build
    // directory.
    return paths.isEmpty ||
        paths.any(id.path.startsWith) ||
        buildConfigs.isPublicAsset(id);
  }
}
