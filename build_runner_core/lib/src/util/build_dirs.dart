// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';

import '../generate/options.dart';
import '../generate/phase.dart';
import '../package_graph/target_graph.dart';

/// Returns whether or not [id] should be built based upon [buildDirs],
/// [phase], [targetGraph], and optional [buildFilters].
///
/// The logic for this is as follows:
///
/// - If any [buildFilters] are supplied, then this only returns `true` if [id]
///   explicitly matches one of the filters.
/// - If no [buildFilters] are supplied, then the old behavior applies - all
///   build to source builders and all public assets (according to
///   [TargetGraph.isPublicAsset]) are always built.
/// - Regardless of the [buildFilters] setting, if [buildDirs] is supplied then
///   `id.path` must start with one of the specified directory names.
bool shouldBuildForDirs(
  AssetId id, {
  required Set<String> buildDirs,
  required BuildPhase phase,
  required TargetGraph targetGraph,
  Set<BuildFilter> buildFilters = const {},
}) {
  if (buildFilters.isEmpty) {
    // Build non-hidden and public assets
    if (!phase.hideOutput) return true;

    if (targetGraph.isPublicAsset(id)) return true;
  } else {
    if (!buildFilters.any((f) => f.matches(id))) {
      return false;
    }
  }

  return buildDirs.isEmpty ||
      targetGraph.isPublicAsset(id) ||
      buildDirs.any(id.path.startsWith);
}
