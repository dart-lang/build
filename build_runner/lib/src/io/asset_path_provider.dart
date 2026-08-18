// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';

/// Converts [AssetId]s and cache paths to filesystem paths.
abstract interface class AssetPathProvider {
  /// Converts [id] to a path.
  ///
  /// Set [hide] to get a path in the hidden "build cache" folder instead of the
  /// directory containing manually written source code.
  ///
  /// Set [checkWriteAllowed] to throw if the path is read only.
  String pathFor(
    AssetId id, {
    required bool hide,
    bool checkWriteAllowed = false,
  });

  /// Converts [relativePath] within the cache directory to a filesystem path.
  String cachePathFor(String relativePath);
}
