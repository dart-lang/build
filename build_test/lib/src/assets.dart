// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:build/build.dart';

import 'in_memory_writer.dart';

int _nextId = 0;
AssetId makeAssetId([String assetIdString]) {
  if (assetIdString == null) {
    assetIdString = 'a|web/asset_$_nextId.txt';
    _nextId++;
  }
  return new AssetId.parse(assetIdString);
}

void addAssets(Map<AssetId, dynamic> assets, InMemoryAssetWriter writer) {
  assets.forEach((id, value) {
    if (value is String) {
      writer.assets[id] = new DatedString(value);
    } else if (value is List<int>) {
      writer.assets[id] = new DatedBytes(value);
    } else {
      throw 'asset values must be of type `String` or `List<int>`, got '
          '${value.runtimeType}.';
    }
  });
}
