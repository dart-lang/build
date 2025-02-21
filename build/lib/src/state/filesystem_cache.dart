// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import '../asset/id.dart';
import 'lru_cache.dart';

/// Cache for file existence and contents.
///
/// TODO(davidmorgan): benchmark, optimize the caching strategy.
abstract interface class FilesystemCache {
  /// Clears all [ids] from all caches.
  ///
  /// Waits for any pending reads to complete first.
  Future<void> invalidate(Iterable<AssetId> ids);

  /// Whether [id] exists.
  ///
  /// Returns a cached result if available, or caches and returns `ifAbsent()`.
  Future<bool> exists(AssetId id, {required Future<bool> Function() ifAbsent});

  /// Reads [id] as bytes.
  ///
  /// Returns a cached result if available, or caches and returns `ifAbsent()`.
  Future<Uint8List> readAsBytes(
    AssetId id, {
    required Future<Uint8List> Function() ifAbsent,
  });

  /// Reads [id] as a `String`.
  ///
  /// Returns a cached result if available, or caches and returns `ifAbsent()`.
  Future<String> readAsString(
    AssetId id, {
    Encoding encoding = utf8,
    required Future<Uint8List> Function() ifAbsent,
  });
}

/// [FilesystemCache] that always reads from the underlying source.
class PassthroughFilesystemCache implements FilesystemCache {
  const PassthroughFilesystemCache();

  @override
  Future<void> invalidate(Iterable<AssetId> ids) async {}

  @override
  Future<bool> exists(
    AssetId id, {
    required Future<bool> Function() ifAbsent,
  }) => ifAbsent();

  @override
  Future<Uint8List> readAsBytes(
    AssetId id, {
    required Future<Uint8List> Function() ifAbsent,
  }) => ifAbsent();

  @override
  Future<String> readAsString(
    AssetId id, {
    Encoding encoding = utf8,
    required Future<Uint8List> Function() ifAbsent,
  }) async => encoding.decode(await ifAbsent());
}

/// [FilesystemCache] that stores data in memory.
class InMemoryFilesystemCache implements FilesystemCache {
  /// Cached results of [readAsBytes].
  final _bytesContentCache = LruCache<AssetId, Uint8List>(
    1024 * 1024,
    1024 * 1024 * 512,
    (value) => value.lengthInBytes,
  );

  /// Pending [readAsBytes] operations.
  final _pendingBytesContentCache = <AssetId, Future<Uint8List>>{};

  /// Cached results of [exists].
  ///
  /// Don't bother using an LRU cache for this since it's just booleans.
  final _canReadCache = <AssetId, Future<bool>>{};

  /// Cached results of [readAsString].
  ///
  /// These are computed and stored lazily using [readAsBytes].
  ///
  /// Only files read with [utf8] encoding (the default) will ever be cached.
  final _stringContentCache = LruCache<AssetId, String>(
    1024 * 1024,
    1024 * 1024 * 512,
    (value) => value.length,
  );

  /// Pending `readAsString` operations.
  final _pendingStringContentCache = <AssetId, Future<String>>{};

  @override
  Future<void> invalidate(Iterable<AssetId> ids) async {
    // First finish all pending operations, as they will write to the cache.
    for (var id in ids) {
      await _canReadCache.remove(id);
      await _pendingBytesContentCache.remove(id);
      await _pendingStringContentCache.remove(id);
    }
    for (var id in ids) {
      _bytesContentCache.remove(id);
      _stringContentCache.remove(id);
    }
  }

  @override
  Future<bool> exists(
    AssetId id, {
    required Future<bool> Function() ifAbsent,
  }) => _canReadCache.putIfAbsent(id, ifAbsent);

  @override
  Future<Uint8List> readAsBytes(
    AssetId id, {
    required Future<Uint8List> Function() ifAbsent,
  }) {
    var cached = _bytesContentCache[id];
    if (cached != null) return Future.value(cached);

    return _pendingBytesContentCache.putIfAbsent(id, () async {
      final result = await ifAbsent();
      _bytesContentCache[id] = result;
      unawaited(_pendingBytesContentCache.remove(id));
      return result;
    });
  }

  @override
  Future<String> readAsString(
    AssetId id, {
    Encoding encoding = utf8,
    required Future<Uint8List> Function() ifAbsent,
  }) async {
    if (encoding != utf8) {
      final bytes = await readAsBytes(id, ifAbsent: ifAbsent);
      return encoding.decode(bytes);
    }

    var cached = _stringContentCache[id];
    if (cached != null) return cached;

    return _pendingStringContentCache.putIfAbsent(id, () async {
      final bytes = await ifAbsent();
      final result = _stringContentCache[id] = utf8.decode(bytes);
      unawaited(_pendingStringContentCache.remove(id));
      return result;
    });
  }
}
