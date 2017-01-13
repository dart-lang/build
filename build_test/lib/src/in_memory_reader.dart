// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';

import 'in_memory_writer.dart';

class InMemoryAssetReader implements AssetReader {
  final Map<AssetId, DatedValue> assets;

  InMemoryAssetReader([Map<AssetId, DatedValue> sourceAssets])
      : assets = sourceAssets ?? <AssetId, DatedValue>{};

  @override
  Future<bool> hasInput(AssetId id) {
    return new Future.value(assets.containsKey(id));
  }

  @override
  Future<List<int>> readAsBytes(AssetId id) async {
    if (!await hasInput(id)) throw new AssetNotFoundException(id);
    return assets[id].bytesValue;
  }

  @override
  Future<String> readAsString(AssetId id, {Encoding encoding: UTF8}) async {
    if (!await hasInput(id)) throw new AssetNotFoundException(id);
    return assets[id].stringValue;
  }

  void cacheBytesAsset(AssetId id, List<int> bytes) {
    assets[id] = new DatedBytes(bytes);
  }

  void cacheStringAsset(AssetId id, String contents) {
    assets[id] = new DatedString(contents);
  }
}
