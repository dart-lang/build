// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import '../../build.dart';

/// Cache for file existence and contents.
///
/// TODO(davidmorgan): benchmark, optimize the caching strategy.
abstract interface class FilesystemCache {
  /// Clears all [ids] from all caches.
  ///
  /// Waits for any pending reads to complete first.
  void invalidate(Iterable<AssetId> ids);

  void flush();

  /// Whether [id] exists.
  ///
  /// Returns a cached result if available, or caches and returns `ifAbsent()`.
  bool exists(AssetId id, {required bool Function() ifAbsent});

  /// Reads [id] as bytes.
  ///
  /// Returns a cached result if available, or caches and returns `ifAbsent()`.
  Uint8List readAsBytes(AssetId id, {required Uint8List Function() ifAbsent});

  void writeAsBytes(
    AssetId id,
    List<int> contents, {
    required void Function() writer,
  });

  /// Reads [id] as a `String`.
  ///
  /// Returns a cached result if available, or caches and returns `ifAbsent()`.
  String readAsString(
    AssetId id, {
    Encoding encoding = utf8,
    required Uint8List Function() ifAbsent,
  });

  void writeAsString(
    AssetId id,
    String contents, {
    Encoding encoding = utf8,
    required void Function() writer,
  });

  void delete(AssetId id, {required void Function() deleter});
}

/// [FilesystemCache] that always reads from the underlying source.
class PassthroughFilesystemCache implements FilesystemCache {
  const PassthroughFilesystemCache();

  @override
  void invalidate(Iterable<AssetId> ids) {}

  @override
  void flush() {}

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

  @override
  void writeAsBytes(
    AssetId id,
    List<int> contents, {
    required void Function() writer,
  }) => writer();

  @override
  void writeAsString(
    AssetId id,
    String contents, {
    Encoding encoding = utf8,
    required void Function() writer,
  }) => writer();

  @override
  void delete(AssetId id, {required void Function() deleter}) => deleter();
}

/// [FilesystemCache] that stores data in memory.
class InMemoryFilesystemCache implements FilesystemCache {
  /// Cached results of [readAsBytes].
  final _bytesContentCache = <AssetId, Uint8List>{};

  /// Cached results of [exists].
  ///
  /// Don't bother using an LRU cache for this since it's just booleans.
  final _canReadCache = <AssetId, bool>{};

  /// Cached results of [readAsString].
  ///
  /// These are computed and stored lazily using [readAsBytes].
  ///
  /// Only files read with [utf8] encoding (the default) will ever be cached.
  final _stringContentCache = <AssetId, String>{};

  final _pendingWrites = <AssetId, void Function()>{};
  final _pendingDeletes = <AssetId, void Function()>{};

  @override
  void invalidate(Iterable<AssetId> ids) {
    for (var id in ids) {
      _pendingWrites.remove(id);
      _pendingDeletes.remove(id);
      _canReadCache.remove(id);
      _bytesContentCache.remove(id);
      _stringContentCache.remove(id);
    }
  }

  @override
  void flush() {
    for (final write in _pendingWrites.values) {
      write();
    }
    for (final delete in _pendingDeletes.values) {
      delete();
    }
    _pendingWrites.clear();
    _pendingDeletes.clear();
  }

  @override
  bool exists(AssetId id, {required bool Function() ifAbsent}) {
    final maybeResult = _canReadCache[id];
    if (maybeResult != null) return maybeResult;
    return _canReadCache[id] = ifAbsent();
  }

  @override
  Uint8List readAsBytes(AssetId id, {required Uint8List Function() ifAbsent}) {
    final maybeResult = _bytesContentCache[id];
    if (maybeResult != null) return maybeResult;

    // Not in cache. Check pending writes and deletes.
    if (_pendingDeletes.containsKey(id)) throw AssetNotFoundException(id);
    if (_pendingWrites.containsKey(id)) {
      throw StateError('Should be in cache: $id');
    }

    // Read and cache.
    final bytes = _bytesContentCache[id] = ifAbsent();
    // Might not be a valid String, only convert to String when read as String.
    _stringContentCache.remove(id);
    return bytes;
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

    // Not in cache. Check pending writes and deletes.
    if (_pendingDeletes.containsKey(id)) throw AssetNotFoundException(id);
    if (_pendingWrites.containsKey(id)) {
      // Might have been written as bytes; only cached as String when it's
      // read as String, because it might not be a valid String.
      final bytes = _bytesContentCache[id];
      if (bytes == null) {
        throw StateError('Should be in cache: $id');
      } else {
        return _stringContentCache[id] = utf8.decode(_bytesContentCache[id]!);
      }
    }

    final bytes = ifAbsent();
    _bytesContentCache[id] = bytes;
    return _stringContentCache[id] = utf8.decode(bytes);
  }

  @override
  void writeAsBytes(
    AssetId id,
    List<int> contents, {
    required void Function() writer,
  }) {
    // [contents] might not be a valid string so defer trying to
    // decode it until if/when it's read as a string.
    _stringContentCache.remove(id);
    _bytesContentCache[id] =
        (contents is Uint8List ? contents : Uint8List.fromList(contents));
    _canReadCache[id] = true;
    _pendingDeletes.remove(id);
    _pendingWrites[id] = writer;
  }

  @override
  void writeAsString(
    AssetId id,
    String contents, {
    Encoding encoding = utf8,
    required void Function() writer,
  }) {
    // Strings are only cached if utf8.
    if (encoding == utf8) {
      _stringContentCache[id] = contents;
    } else {
      _stringContentCache.remove(id);
    }

    final encoded = encoding.encode(contents);
    _bytesContentCache[id] =
        encoded is Uint8List ? encoded : Uint8List.fromList(encoded);

    _canReadCache[id] = true;
    _pendingDeletes.remove(id);
    _pendingWrites[id] = writer;
  }

  @override
  void delete(AssetId id, {required void Function() deleter}) {
    _stringContentCache.remove(id);
    _bytesContentCache.remove(id);
    _canReadCache[id] = false;
    _pendingWrites.remove(id);
    _pendingDeletes[id] = deleter;
  }
}
