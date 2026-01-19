// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';

import '../constants.dart';

/// Converts [AssetId]s to paths.
abstract interface class AssetPathProvider {
  /// Converts [id] to a path.
  ///
  /// Set [hide] to get a path in the hidden "build cache" folder instead of the
  /// directory containing manually written source code.
  ///
  /// Set [checkDeleteAllowed] to throw if the path is read only.
  String pathFor(
    AssetId id, {
    required bool hide,
    bool checkDeleteAllowed = false,
  });

  /// Returns [id] hidden in [buildCachePackage].
  static AssetId hide(AssetId id, String buildCachePackage) => AssetId(
    buildCachePackage,
    '$generatedOutputDirectory/${id.package}/${id.path}',
  );
}
