// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../asset/id.dart';

/// Converts [AssetId] to paths.
abstract interface class AssetPathProvider {
  String pathFor(AssetId id);
}

/// Applies a function to an existing [AssetPathProvider].
class OverlayAssetPathProvider implements AssetPathProvider {
  AssetPathProvider delegate;
  AssetId Function(AssetId) overlay;

  OverlayAssetPathProvider({required this.delegate, required this.overlay});

  @override
  String pathFor(AssetId id) => delegate.pathFor(overlay(id));
}
