// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';
import 'package:glob/glob.dart';

import 'in_memory_writer.dart';

class InMemoryAssetReader implements AssetReader {
  final Map<AssetId, DatedValue> assets;
  final String rootPackage;

  InMemoryAssetReader({Map<AssetId, DatedValue> sourceAssets, this.rootPackage})
      : assets = sourceAssets ?? <AssetId, DatedValue>{};

  @override
  FutureOr<bool> canRead(AssetId id) => assets.containsKey(id);

  @override
  Future<List<int>> readAsBytes(AssetId id) async {
    if (!await canRead(id)) throw new AssetNotFoundException(id);
    return assets[id].bytesValue;
  }

  @override
  Future<String> readAsString(AssetId id, {Encoding encoding: UTF8}) async {
    if (!await canRead(id)) throw new AssetNotFoundException(id);
    return assets[id].stringValue;
  }

  @override
  Iterable<AssetId> findAssets(Glob glob) {
    if (rootPackage == null) {
      throw new UnsupportedError('Root package is required to use findAssets');
    }
    return assets.keys
        .where((id) => id.package == rootPackage && glob.matches(id.path));
  }

  void cacheBytesAsset(AssetId id, List<int> bytes) {
    assets[id] = new DatedBytes(bytes);
  }

  void cacheStringAsset(AssetId id, String contents) {
    assets[id] = new DatedString(contents);
  }
}
