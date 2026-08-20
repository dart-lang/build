// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../build_file.dart';
import 'build_file_change.dart';

/// Merges [BuildFileChange] events into a set of changed [AssetFile]s,
/// discarding the change types.
Set<AssetFile> collectChanges(List<List<BuildFileChange>> changes) {
  final result = <AssetFile>{};
  for (final change in changes.expand((l) => l)) {
    final assetFile = change.assetFile;
    if (assetFile != null) {
      result.add(assetFile);
    }
  }
  return result;
}
