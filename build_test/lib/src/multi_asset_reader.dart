// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:build/build.dart';
import 'package:glob/glob.dart';

/// An [AssetReader] that delegates to multiple other asset readers.
///
/// [MultiAssetReader] attempts to check every provided [AssetReader] to see if
/// they are capable of reading an [AssetId], otherwise checks the next reader.
///
/// **INTERNAL ONLY**: Only used as part of `build_test` for now for allowing a
/// combination of "fake" assets (in-memory provided by a test) and "real"
/// assets (i.e. dependencies we want resolved).
class MultiAssetReader implements AssetReader {
  final List<AssetReader> _readers;

  const MultiAssetReader(this._readers);

  @override
  Future<bool> hasInput(AssetId id) async {
    for (var reader in _readers) {
      if (await reader.hasInput(id)) {
        return true;
      }
    }
    return false;
  }

  @override
  Future<List<int>> readAsBytes(AssetId id) async =>
      (await _readerWith(id)).readAsBytes(id);

  @override
  Future<String> readAsString(AssetId id, {Encoding encoding: UTF8}) async =>
      (await _readerWith(id)).readAsString(id, encoding: encoding);

  /// Returns all readable assets matching [glob] under the root package.
  ///
  /// **NOTE**: This is a combined view of all provided readers.
  @override
  Iterable<AssetId> findAssets(Glob glob) => new CombinedIterableView(
      _readers.map((reader) => reader.findAssets(glob)));

  /// Returns the first [AssetReader] that contains [id].
  ///
  /// Otherwise throws [AssetNotFoundException].
  Future<AssetReader> _readerWith(AssetId id) async {
    for (var reader in _readers) {
      if (await reader.hasInput(id)) {
        return reader;
      }
    }
    throw new AssetNotFoundException(id);
  }
}
