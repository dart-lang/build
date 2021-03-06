// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:async/async.dart';
import 'package:build/build.dart';
import 'package:glob/glob.dart';

/// A [MultiPackageAssetReader] that delegates to multiple other asset
/// readers.
///
/// [MultiAssetReader] attempts to check every provided
/// [MultiPackageAssetReader] to see if they are capable of reading an
/// [AssetId], otherwise checks the next reader.
class MultiAssetReader extends AssetReader implements MultiPackageAssetReader {
  final List<MultiPackageAssetReader> _readers;

  MultiAssetReader(this._readers);

  @override
  Future<bool> canRead(AssetId id) async {
    for (var reader in _readers) {
      if (await reader.canRead(id)) {
        return true;
      }
    }
    return false;
  }

  @override
  Future<List<int>> readAsBytes(AssetId id) async =>
      (await _readerWith(id)).readAsBytes(id);

  @override
  Future<String> readAsString(AssetId id, {Encoding encoding = utf8}) async =>
      (await _readerWith(id)).readAsString(id, encoding: encoding);

  /// Returns all readable assets matching [glob] under [package].
  ///
  /// **NOTE**: This is a combined view of all provided readers. As such it is
  /// possible that an [AssetId] will be iterated over more than once, unlike
  /// other implementations of [AssetReader].
  @override
  Stream<AssetId> findAssets(Glob glob, {String? package}) => StreamGroup.merge(
      _readers.map((reader) => reader.findAssets(glob, package: package)));

  /// Returns the first [AssetReader] that contains [id].
  ///
  /// Otherwise throws [AssetNotFoundException].
  Future<AssetReader> _readerWith(AssetId id) async {
    for (var reader in _readers) {
      if (await reader.canRead(id)) {
        return reader;
      }
    }
    throw AssetNotFoundException(id);
  }
}
