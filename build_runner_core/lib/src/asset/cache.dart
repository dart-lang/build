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
import 'reader.dart';

/// An [AssetReader] that caches all results from the delegate.
///
/// Assets are cached until [invalidate] is invoked.
///
/// Does not implement [findAssets].
class CachingAssetReader implements AssetReader {
  /// Cached results of [readAsBytes].
  final _bytesContentCache = LruCache<AssetId, List<int>>(
      1024 * 1024,
      1024 * 1024 * 512,
      (value) => value is Uint8List ? value.lengthInBytes : value.length * 8);

  /// Pending [readAsBytes] operations.
  final _pendingBytesContentCache = <AssetId, Future<List<int>>>{};

  /// Cached results of [canRead].
  ///
  /// Don't bother using an LRU cache for this since it's just booleans.
  final _canReadCache = <AssetId, FutureOr<bool>>{};

  /// Cached results of [readAsString].
  ///
  /// These are computed and stored lazily using [readAsBytes].
  ///
  /// Only files read with [utf8] encoding (the default) will ever be cached.
  final _stringContentCache = LruCache<AssetId, String>(
      1024 * 1024, 1024 * 1024 * 512, (value) => value.length);

  /// Pending `readAsString` operations.
  final _pendingStringContentCache = <AssetId, Future<String>>{};

  final AssetReader _delegate;

  CachingAssetReader._(this._delegate);

  factory CachingAssetReader(AssetReader delegate) =>
      delegate is PathProvidingAssetReader
          ? _PathProvidingCachingAssetReader._(delegate)
          : CachingAssetReader._(delegate);

  @override
  FutureOr<bool> canRead(AssetId id) => _canReadCache.putIfAbsent(id, () {
        var canRead = _delegate.canRead(id);
        if (canRead is Future<bool>) {
          canRead.then((result) {
            if (_canReadCache[id] == canRead) _canReadCache[id] = result;
          });
        }
        return canRead;
      });

  @override
  FutureOr<Digest> digest(AssetId id) => _delegate.digest(id);

  @override
  Stream<AssetId> findAssets(Glob glob) =>
      throw UnimplementedError('unimplemented!');

  @override
  FutureOr<List<int>> readAsBytes(AssetId id, {bool cache = true}) {
    var cached = _bytesContentCache[id];
    if (cached != null) return cached;

    if (_pendingBytesContentCache.containsKey(id)) {
      return _pendingBytesContentCache[id];
    }
    var bytes = _delegate.readAsBytes(id);
    if (bytes is List<int>) {
      if (cache) _bytesContentCache[id] = bytes;
      return bytes;
    } else {
      var futureBytes = bytes as Future<List<int>>;
      return _pendingBytesContentCache[id] = futureBytes.then((result) {
        if (cache) _bytesContentCache[id] = result;
        _pendingBytesContentCache.remove(id);
        return result;
      });
    }
  }

  @override
  FutureOr<String> readAsString(AssetId id, {Encoding encoding}) {
    encoding ??= utf8;

    if (encoding != utf8) {
      // Fallback case, we never cache the String value for the non-default,
      // encoding but we do allow it to cache the bytes.
      var result = readAsBytes(id);
      if (result is List<int>) {
        return encoding.decode(result);
      } else {
        return (result as Future<List<int>>).then(encoding.decode);
      }
    }

    var cached = _stringContentCache[id];
    if (cached != null) return cached;

    if (_pendingStringContentCache.containsKey(id)) {
      return _pendingStringContentCache[id];
    }
    var bytes = readAsBytes(id, cache: false);
    if (bytes is List<int>) {
      var decoded = encoding.decode(bytes);
      _stringContentCache[id] = decoded;
      return decoded;
    } else {
      var futureBytes = bytes as Future<List<int>>;
      return _pendingStringContentCache[id] = futureBytes.then((result) {
        var decoded = encoding.decode(result);
        _stringContentCache[id] = decoded;
        _pendingStringContentCache.remove(id);
        return decoded;
      });
    }
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

/// A version of a [CachingAssetReader] that implements
/// [PathProvidingAssetReader].
class _PathProvidingCachingAssetReader extends CachingAssetReader
    implements PathProvidingAssetReader {
  @override
  PathProvidingAssetReader get _delegate =>
      super._delegate as PathProvidingAssetReader;

  _PathProvidingCachingAssetReader._(AssetReader delegate) : super._(delegate);

  @override
  String pathTo(AssetId id) => _delegate.pathTo(id);
}
