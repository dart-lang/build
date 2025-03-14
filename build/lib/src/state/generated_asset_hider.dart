// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../asset/id.dart';

/// Optionally modifies the storage location of assets.
///
/// `AssetGraph` provides an implementation of this interface that moves
/// "hidden" generated files to the "build cache" path under `rootPackage`.
abstract interface class GeneratedAssetHider {
  /// Returns [id] or an updated [id].
  AssetId maybeHide(AssetId id, String rootPackage);
}

/// [GeneratedAssetHider] that does nothing.
class NoopGeneratedAssetHider implements GeneratedAssetHider {
  const NoopGeneratedAssetHider();

  @override
  AssetId maybeHide(AssetId id, String _) => id;
}
