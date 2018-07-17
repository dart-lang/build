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
  final _bytesContentCache =
      new LruCache<AssetId, List<int>>(1024 * 1024, 1024 * 1024 * 512, (value) {
    if (value is Uint8List) {
      return value.lengthInBytes;
    } else {
      return value.length * 8;
    }
  });

  /// Pending [readAsBytes] operations.
  final _pendingBytesContentCache = <AssetId, Future<List<int>>>{};

  /// Cached results of [canRead].
  ///
  /// Don't bother using an LRU cache for this since it's just booleans.
  final _canReadCache = <AssetId, Future<bool>>{};

  /// Cached results of [readAsString], per [Encoding] type used.
  ///
  /// These are computed and stored lazily using [readAsBytes].
  final _stringContentCache = new LruCache<_AssetIdWithEncoding, String>(
      1024 * 1024, 1024 * 1024 * 512, (value) => value.length);

  /// Pending `readAsString` operations.
  final _pendingStringContentCache = <AssetId, Map<Encoding, Future<String>>>{};

  /// All [Encoding]s ever used.
  final _encodingsUsed = new Set<Encoding>();

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
              // Defensive tactic for unawaited futures which could potentially
              // leak old data into the cache.
              if (_pendingBytesContentCache.containsKey(id)) {
                if (cache) _bytesContentCache[id] = result;
                _pendingBytesContentCache.remove(id);
              }
              return result;
            }));
  }

  @override
  Future<String> readAsString(AssetId id, {Encoding encoding}) {
    encoding ??= utf8;

    var key = new _AssetIdWithEncoding(id, encoding);
    var cached = _stringContentCache[key];
    if (cached != null) return new Future.value(cached);

    return _pendingStringContentCache.putIfAbsent(id, () => {}).putIfAbsent(
        encoding,
        () => readAsBytes(id, cache: false).then((bytes) {
              var decoded = encoding.decode(bytes);
              // Defensive tactic for unawaited futures which could potentially
              // leak old data into the cache.
              if (_pendingStringContentCache.containsKey(id)) {
                _stringContentCache[key] = decoded;
                _pendingStringContentCache.remove(id);
              }
              return decoded;
            }));
  }

  /// Clears all [ids] from all caches.
  void invalidate(Iterable<AssetId> ids) {
    for (var id in ids) {
      _bytesContentCache.remove(id);
      _canReadCache.remove(id);
      for (var encoding in _encodingsUsed) {
        _stringContentCache.remove(new _AssetIdWithEncoding(id, encoding));
      }

      _pendingBytesContentCache.remove(id);
      _pendingStringContentCache.remove(id);
    }
  }
}

/// Combines an [AssetId] and an [Encoding] for use as a hash key.
class _AssetIdWithEncoding {
  final AssetId id;
  final Encoding encoding;

  _AssetIdWithEncoding(this.id, this.encoding);

  @override
  bool operator ==(other) =>
      other is _AssetIdWithEncoding &&
      other.id == id &&
      other.encoding.name == encoding.name;

  @override
  int get hashCode => id.hashCode ^ encoding.name.hashCode;

  @override
  String toString() => '$id:$encoding';
}
