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

Asset makeAsset([String assetIdString, String contents]) {
  var id = makeAssetId(assetIdString);
  return new Asset(id, contents ?? '$id');
}

Map<AssetId, Asset> makeAssets(Map<String, String> assetsMap) {
  var assets = <AssetId, Asset>{};
  assetsMap.forEach((idString, content) {
    var asset = makeAsset(idString, content);
    assets[asset.id] = asset;
  });
  return assets;
}

void addAssets(Iterable<Asset> assets, InMemoryAssetWriter writer) {
  for (var asset in assets) {
    writer.assets[asset.id] = new DatedString(asset.stringContents);
  }
}
