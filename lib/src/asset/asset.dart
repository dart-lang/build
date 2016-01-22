// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library build.src.asset.asset;

import 'id.dart';

/// A fully realized asset whose content is available synchronously.
class Asset {
  /// The id for this asset.
  final AssetId id;

  /// The content for this asset.
  final String contents;

  Asset(this.id, this.contents);

  String toString() => 'Asset: $id';
}
