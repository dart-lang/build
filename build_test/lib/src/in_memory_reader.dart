// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';
import 'package:glob/glob.dart';

import 'in_memory_writer.dart';

/// An implementation of [AssetReader] with primed in-memory assets.
class InMemoryAssetReader implements MultiPackageAssetReader {
  final Map<AssetId, DatedValue> assets;
  final String rootPackage;

  /// Create a new asset reader that contains [sourceAssets].
  ///
  /// May optionally define a [rootPackage], which is required for some APIs.
  InMemoryAssetReader({Map<AssetId, DatedValue> sourceAssets, this.rootPackage})
      : assets = sourceAssets ?? <AssetId, DatedValue>{};

  @override
  Future<bool> canRead(AssetId id) async => assets.containsKey(id);

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
  Iterable<AssetId> findAssets(Glob glob, {String package}) {
    package ??= rootPackage;
    if (package == null) {
      throw new UnsupportedError(
          'Root package is required to use findAssets without providing an '
          'explicit package.');
    }
    return assets.keys
        .where((id) => id.package == package && glob.matches(id.path));
  }

  void cacheBytesAsset(AssetId id, List<int> bytes) {
    assets[id] = new DatedBytes(bytes);
  }

  void cacheStringAsset(AssetId id, String contents) {
    assets[id] = new DatedString(contents);
  }
}
