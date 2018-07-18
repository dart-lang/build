// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:build/build.dart';
import 'package:crypto/crypto.dart';
import 'package:glob/glob.dart';

import 'lru_cache.dart';

/// An [AssetReader] that wraps another [AssetReader] and caches all results
/// from it.
///
/// Assets are cached until [invalidate] is invoked.
///
/// Does not implement [findAssets].
class CachingAssetReader implements AssetReader {
  /// Cached results of [readAsBytes].
  final _bytesContentCache = new LruCache<AssetId, List<int>>(
      1024 * 1024,
      1024 * 1024 * 512,
      (value) => value is Uint8List ? value.lengthInBytes : value.length * 8);

  /// Pending [readAsBytes] operations.
  final _pendingBytesContentCache = <AssetId, Future<List<int>>>{};

  /// Cached results of [canRead].
  ///
  /// Don't bother using an LRU cache for this since it's just booleans.
  final _canReadCache = <AssetId, Future<bool>>{};

  /// Cached results of [readAsString].
  ///
  /// These are computed and stored lazily using [readAsBytes].
  ///
  /// Only files read with [utf8] encoding (the default) will ever be cached.
  final _stringContentCache = new LruCache<AssetId, String>(
      1024 * 1024, 1024 * 1024 * 512, (value) => value.length);

  /// Pending `readAsString` operations.
  final _pendingStringContentCache = <AssetId, Map<Encoding, Future<String>>>{};

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
  Future<List<int>> readAsBytes(AssetId id, {bool cache = true}) {
    var cached = _bytesContentCache[id];
    if (cached != null) return new Future.value(cached);

    return _pendingBytesContentCache.putIfAbsent(
        id,
        () => _delegate.readAsBytes(id).then((result) {
              if (cache) _bytesContentCache[id] = result;
              _pendingBytesContentCache.remove(id);
              return result;
            }));
  }

  @override
  Future<String> readAsString(AssetId id, {Encoding encoding}) {
    encoding ??= utf8;

    if (encoding != utf8) {
      // Fallback case, we never cache for the non-default encoding.
      return readAsBytes(id).then(encoding.decode);
    }

    var cached = _stringContentCache[id];
    if (cached != null) return new Future.value(cached);

    return _pendingStringContentCache.putIfAbsent(id, () => {}).putIfAbsent(
        encoding,
        () => readAsBytes(id, cache: false).then((bytes) {
              var decoded = encoding.decode(bytes);
              _stringContentCache[id] = decoded;
              _pendingStringContentCache.remove(id);
              return decoded;
            }));
  }

  /// Clears all [ids] from all caches.
  void invalidate(Iterable<AssetId> ids) {
    for (var id in ids) {
      _bytesContentCache.remove(id);
      _canReadCache.remove(id);
      _stringContentCache.remove(id);

      _pendingBytesContentCache.remove(id);
      _pendingStringContentCache.remove(id);
    }
  }
}
