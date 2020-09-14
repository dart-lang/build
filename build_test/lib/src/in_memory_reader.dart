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
class InMemoryAssetReader extends AssetReader
    implements MultiPackageAssetReader, RecordingAssetReader {
  final Map<AssetId, List<int>> assets;
  final String rootPackage;

  @override
  final Set<AssetId> assetsRead = <AssetId>{};

  /// Create a new asset reader that contains [sourceAssets].
  ///
  /// Any items in [sourceAssets] which are [String]s will be converted into
  /// a [List<int>] of bytes.
  ///
  /// May optionally define a [rootPackage], which is required for some APIs.
  InMemoryAssetReader({Map<AssetId, dynamic> sourceAssets, this.rootPackage})
      : assets = _assetsAsBytes(sourceAssets) ?? <AssetId, List<int>>{};

  /// Create a new asset reader backed by [assets].
  InMemoryAssetReader.shareAssetCache(this.assets, {this.rootPackage});

  static Map<AssetId, List<int>> _assetsAsBytes(Map<AssetId, dynamic> assets) {
    if (assets == null || assets.isEmpty) {
      return {};
    }
    final output = <AssetId, List<int>>{};
    assets.forEach((id, stringOrBytes) {
      if (stringOrBytes is List<int>) {
        output[id] = stringOrBytes;
      } else if (stringOrBytes is String) {
        output[id] = utf8.encode(stringOrBytes);
      } else {
        throw UnsupportedError('Invalid asset contents: $stringOrBytes.');
      }
    });
    return output;
  }

  @override
  Future<bool> canRead(AssetId id) async {
    assetsRead.add(id);
    return assets.containsKey(id);
  }

  @override
  Future<List<int>> readAsBytes(AssetId id) async {
    if (!await canRead(id)) throw AssetNotFoundException(id);
    assetsRead.add(id);
    return assets[id];
  }

  @override
  Future<String> readAsString(AssetId id, {Encoding encoding = utf8}) async {
    if (!await canRead(id)) throw AssetNotFoundException(id);
    assetsRead.add(id);
    return utf8.decode(assets[id]);
  }

  @override
  Stream<AssetId> findAssets(Glob glob, {String package}) {
    package ??= rootPackage;
    if (package == null) {
      throw UnsupportedError(
          'Root package is required to use findAssets without providing an '
          'explicit package.');
    }
    return Stream.fromIterable(assets.keys
        .where((id) => id.package == package && glob.matches(id.path)));
  }

  void cacheBytesAsset(AssetId id, List<int> bytes) {
    assets[id] = bytes;
  }

  void cacheStringAsset(AssetId id, String contents, {Encoding encoding}) {
    encoding ??= utf8;
    assets[id] = encoding.encode(contents);
  }
}
