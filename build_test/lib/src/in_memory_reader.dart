// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';
import 'package:glob/glob.dart';

/// An [AssetReader] that records which assets have been read to [assetsRead].
abstract class RecordingAssetReader implements AssetReader {
  Iterable<AssetId> get assetsRead;
}

/// An implementation of [AssetReader] with primed in-memory assets.
class InMemoryAssetReader
    implements MultiPackageAssetReader, RecordingAssetReader {
  final Map<AssetId, List<int>> assets;
  final String rootPackage;

  @override
  final Set<AssetId> assetsRead;

  /// Create a new asset reader that contains [sourceAssets].
  ///
  /// May optionally define a [rootPackage], which is required for some APIs.
  InMemoryAssetReader({Map<AssetId, dynamic> sourceAssets, this.rootPackage})
      : assets = _convertAssetsToBytes(sourceAssets) ?? <AssetId, List<int>>{},
        assetsRead = new Set<AssetId>();

  static Map<AssetId, List<int>> _convertAssetsToBytes(
      Map<AssetId, dynamic> original) {
    var newMap = <AssetId, List<int>>{};
    original.forEach((id, content) {
      if (content is String) content = UTF8.encode(content as String);
      newMap[id] = content as List<int>;
    });
    return newMap;
  }

  @override
  Future<bool> canRead(AssetId id) async {
    assetsRead.add(id);
    return assets.containsKey(id);
  }

  @override
  Future<List<int>> readAsBytes(AssetId id) async {
    if (!await canRead(id)) throw new AssetNotFoundException(id);
    assetsRead.add(id);
    return assets[id];
  }

  @override
  Future<String> readAsString(AssetId id, {Encoding encoding: UTF8}) async {
    if (!await canRead(id)) throw new AssetNotFoundException(id);
    assetsRead.add(id);
    return UTF8.decode(assets[id]);
  }

  @override
  Stream<AssetId> findAssets(Glob glob, {String package}) {
    package ??= rootPackage;
    if (package == null) {
      throw new UnsupportedError(
          'Root package is required to use findAssets without providing an '
          'explicit package.');
    }
    return new Stream.fromIterable(assets.keys
        .where((id) => id.package == package && glob.matches(id.path)));
  }

  void cacheBytesAsset(AssetId id, List<int> bytes) {
    assets[id] = bytes;
  }

  void cacheStringAsset(AssetId id, String contents, {Encoding encoding}) {
    encoding ??= UTF8;
    assets[id] = encoding.encode(contents);
  }
}
