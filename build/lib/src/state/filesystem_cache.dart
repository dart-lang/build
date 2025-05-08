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
  void invalidate(Iterable<AssetId> ids);

  /// Whether [id] exists.
  ///
  /// Returns a cached result if available, or caches and returns `ifAbsent()`.
  bool exists(AssetId id, {required bool Function() ifAbsent});

  /// Reads [id] as bytes.
  ///
  /// Returns a cached result if available, or caches and returns `ifAbsent()`.
  Uint8List readAsBytes(AssetId id, {required Uint8List Function() ifAbsent});

  /// Reads [id] as a `String`.
  ///
  /// Returns a cached result if available, or caches and returns `ifAbsent()`.
  String readAsString(
    AssetId id, {
    Encoding encoding = utf8,
    required Uint8List Function() ifAbsent,
  });
}

/// [FilesystemCache] that always reads from the underlying source.
class PassthroughFilesystemCache implements FilesystemCache {
  const PassthroughFilesystemCache();

  @override
  Future<void> invalidate(Iterable<AssetId> ids) async {}

  @override
  bool exists(AssetId id, {required bool Function() ifAbsent}) => ifAbsent();

  @override
  Uint8List readAsBytes(AssetId id, {required Uint8List Function() ifAbsent}) =>
      ifAbsent();

  @override
  String readAsString(
    AssetId id, {
    Encoding encoding = utf8,
    required Uint8List Function() ifAbsent,
  }) => encoding.decode(ifAbsent());
}

/// [FilesystemCache] that stores data in memory.
class InMemoryFilesystemCache implements FilesystemCache {
  /// Cached results of [readAsBytes].
  final _bytesContentCache = LruCache<AssetId, Uint8List>(
    1024 * 1024,
    1024 * 1024 * 512,
    (value) => value.lengthInBytes,
  );

  /// Cached results of [exists].
  ///
  /// Don't bother using an LRU cache for this since it's just booleans.
  final _existsCache = <AssetId, bool>{};

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

  @override
  Future<void> invalidate(Iterable<AssetId> ids) async {
    for (var id in ids) {
      _existsCache.remove(id);
      _bytesContentCache.remove(id);
      _stringContentCache.remove(id);
    }
  }

  @override
  bool exists(AssetId id, {required bool Function() ifAbsent}) =>
      _existsCache.putIfAbsent(id, ifAbsent);

  @override
  Uint8List readAsBytes(AssetId id, {required Uint8List Function() ifAbsent}) {
    final maybeResult = _bytesContentCache[id];
    if (maybeResult != null) return maybeResult;

    final result = ifAbsent();
    _bytesContentCache[id] = result;
    return result;
  }

  @override
  String readAsString(
    AssetId id, {
    Encoding encoding = utf8,
    required Uint8List Function() ifAbsent,
  }) {
    if (encoding != utf8) {
      final bytes = readAsBytes(id, ifAbsent: ifAbsent);
      return encoding.decode(bytes);
    }

    final maybeResult = _stringContentCache[id];
    if (maybeResult != null) return maybeResult;

    var bytes = _bytesContentCache[id];
    if (bytes == null) {
      bytes = ifAbsent();
      _bytesContentCache[id] = bytes;
    }
    final result = utf8.decode(bytes);
    _stringContentCache[id] = result;
    return result;
  }
}
