// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';

import 'asset_change.dart';

/// Merges [AssetChange] events into a set of changed [AssetId]s, discarding
/// the change types.
Set<AssetId> collectChanges(List<List<AssetChange>> changes) {
  final result = <AssetId>{};
  for (final change in changes.expand((l) => l)) {
    result.add(change.id);
  }
  return result;
}
