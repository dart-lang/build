// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';

/// Determines whether an asset is hidden.
///
/// That means it's written to the "build cache" instead of the directory
/// containing manually written source code.
abstract interface class GeneratedAssetHider {
  /// Returns whether [id] is hidden.
  bool isHidden(AssetId id);
}

/// [GeneratedAssetHider] that always returns `false`.
class NoopGeneratedAssetHider implements GeneratedAssetHider {
  const NoopGeneratedAssetHider();

  @override
  bool isHidden(AssetId _) => false;
}
