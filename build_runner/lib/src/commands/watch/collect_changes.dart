// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../asset_location.dart';
import 'asset_change.dart';

/// Merges [AssetChange] events into a set of changed [AssetLocation]s,
/// discarding the change types.
Set<AssetLocation> collectChanges(List<List<AssetChange>> changes) {
  final result = <AssetLocation>{};
  for (final change in changes.expand((l) => l)) {
    result.add(change.location);
  }
  return result;
}
