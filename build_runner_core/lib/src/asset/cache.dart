// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';
import 'package:crypto/crypto.dart';
import 'package:glob/glob.dart';

/// An [AssetReader] that wraps another [AssetReader] and caches all results
/// from it.
///
/// Assets are cached until [invalidate] is invoked.
///
/// Does not implement [findAssets].
class CachingAssetReader implements AssetReader {
  /// Cached results of [readAsBytes].
  final _bytesContentCache = <AssetId, Future<List<int>>>{};

  /// Cached results of [canRead].
  final _canReadCache = <AssetId, Future<bool>>{};

  /// Cached results of [readAsString], per [Encoding] type used.
  ///
  /// These are computed and stored lazily using [readAsBytes].
  final _stringContentCache = <AssetId, Map<Encoding, Future<String>>>{};

  /// The [AssetReader] to delegate all reads to.
  final AssetReader _delegate;

  CachingAssetReader(this._delegate);

  @override
  Future<bool> canRead(AssetId id) =>
      _canReadCache.putIfAbsent(id, () => _delegate.canRead(id));

  @override
  Future<Digest> digest(id) => _delegate.digest(id);

  @override
  Stream<AssetId> findAssets(Glob glob) =>
      throw new UnimplementedError('unimplemented!');

  @override
  Future<List<int>> readAsBytes(AssetId id) =>
      _bytesContentCache.putIfAbsent(id, () => _delegate.readAsBytes(id));

  @override
  Future<String> readAsString(AssetId id, {Encoding encoding}) {
    encoding ??= utf8;
    return _stringContentCache
        .putIfAbsent(id, () => {})
        .putIfAbsent(encoding, () => readAsBytes(id).then(encoding.decode));
  }

  /// Clears all [ids] from all caches.
  void invalidate(Iterable<AssetId> ids) {
    for (var id in ids) {
      _bytesContentCache.remove(id);
      _canReadCache.remove(id);
      _stringContentCache.remove(id);
    }
  }
}
