// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';

import '../constants.dart';

/// Converts [AssetId]s to paths.
abstract interface class AssetPathProvider {
  /// Converts [id] to a path.
  ///
  /// Set [inArtifactTree] to get a path in the artifact tree instead of at the
  /// package path.
  ///
  /// Set [checkWriteAllowed] to throw if the path is read only.
  String pathFor(
    AssetId id, {
    required bool inArtifactTree,
    bool checkWriteAllowed = false,
  });

  /// Returns [id] in the artifact tree for [rootPackage].
  static AssetId inArtifactTree(AssetId id, String rootPackage) =>
      AssetId(rootPackage, '$artifactTreePath/${id.package}/${id.path}');
}
