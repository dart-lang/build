// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import '../../build.dart';
import '../asset/id.dart';
import 'lru_cache.dart';

/// Cache for file existence and contents.
///
/// TODO(davidmorgan): benchmark, optimize the caching strategy.
abstract interface class FilesystemCache {
  /// Clears all [ids] from all caches.
  void invalidate(Iterable<AssetId> ids);

  /// Flushes pending writes and deletes.
  void flush();

  /// Whether [id] exists.
  ///
  /// Returns a cached result if available, or caches and returns `ifAbsent()`.
  bool exists(AssetId id, {required bool Function() ifAbsent});

  /// Reads [id] as bytes.
  ///
  /// Returns a cached result if available, or caches and returns `ifAbsent()`.
  Uint8List readAsBytes(AssetId id, {required Uint8List Function() ifAbsent});

  /// Writes [contents] to [id].
  ///
  /// [writer] is a function that does the actual write. If this cache does
  /// write caching, it is not called until [flush], and might not be called at
  /// all if another write to the same asset happens first.
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

  /// Writes [contents] to [id].
  ///
  /// [writer] is a function that does the actual write. If this cache does
  /// write caching, it is not called until [flush], and might not be called at
  /// all if another write to the same asset happens first.
  void writeAsString(
    AssetId id,
    String contents, {
    Encoding encoding = utf8,
    required void Function() writer,
  });

  /// Deletes [id].
  ///
  /// [deleter] is a function that does the actual delete. If this cache does
  /// write caching, it is not called until [flush], and might not be called at
  /// all if another write to the same asset happens first.
  void delete(AssetId id, {required void Function() deleter});
}

/// [FilesystemCache] that always reads from the underlying source.
class PassthroughFilesystemCache implements FilesystemCache {
  const PassthroughFilesystemCache();

  @override
  Future<void> invalidate(Iterable<AssetId> ids) async {}

  @override
  void flush() {}

  @override
  bool exists(AssetId id, {required bool Function() ifAbsent}) => ifAbsent();

  @override
  Uint8List readAsBytes(AssetId id, {required Uint8List Function() ifAbsent}) =>
      ifAbsent();

  @override
  void writeAsBytes(
    AssetId id,
    List<int> contents, {
    required void Function() writer,
  }) => writer();

  @override
  String readAsString(
    AssetId id, {
    Encoding encoding = utf8,
    required Uint8List Function() ifAbsent,
  }) => encoding.decode(ifAbsent());

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

  final _pendingWrites = <AssetId, _PendingWrite>{};

  @override
  Future<void> invalidate(Iterable<AssetId> ids) async {
    if (_pendingWrites.isNotEmpty) {
      throw StateError("Can't invalidate while there are pending writes.");
    }
    for (var id in ids) {
      _existsCache.remove(id);
      _bytesContentCache.remove(id);
      _stringContentCache.remove(id);
    }
  }

  @override
  void flush() {
    for (final write in _pendingWrites.values) {
      write.writer();
    }
    _pendingWrites.clear();
  }

  @override
  bool exists(AssetId id, {required bool Function() ifAbsent}) {
    final maybePendingWrite = _pendingWrites[id];
    if (maybePendingWrite != null) {
      return !maybePendingWrite.isDelete;
    }
    return _existsCache.putIfAbsent(id, ifAbsent);
  }

  @override
  Uint8List readAsBytes(AssetId id, {required Uint8List Function() ifAbsent}) {
    final maybePendingWrite = _pendingWrites[id];
    if (maybePendingWrite != null) {
      // Throws if it's a delete; callers should check [exists] before reading.
      return maybePendingWrite.bytes!;
    }

    final maybeResult = _bytesContentCache[id];
    if (maybeResult != null) return maybeResult;

    final result = ifAbsent();
    _bytesContentCache[id] = result;
    return result;
  }

  @override
  void writeAsBytes(
    AssetId id,
    List<int> contents, {
    required void Function() writer,
  }) {
    _stringContentCache.remove(id);
    _writeBytes(id, contents, writer: writer);
  }

  void _writeBytes(
    AssetId id,
    List<int> contents, {
    required void Function() writer,
  }) {
    final uint8ListContents =
        contents is Uint8List ? contents : Uint8List.fromList(contents);
    _bytesContentCache[id] = uint8ListContents;
    _existsCache[id] = true;
    _pendingWrites[id] = _PendingWrite(
      writer: writer,
      bytes: uint8ListContents,
    );
  }

  @override
  String readAsString(
    AssetId id, {
    Encoding encoding = utf8,
    required Uint8List Function() ifAbsent,
  }) {
    // Encodings other than utf8 do not use `_stringContentCache`. Read as
    // bytes then convert, instead.
    if (encoding != utf8) {
      final bytes = readAsBytes(id, ifAbsent: ifAbsent);
      return encoding.decode(bytes);
    }

    // Check `_stringContentCache` first to use it as a cache for conversion of
    // bytes from _pendingWrites.
    final maybeResult = _stringContentCache[id];
    if (maybeResult != null) return maybeResult;

    final bytes = readAsBytes(id, ifAbsent: ifAbsent);
    final result = utf8.decode(bytes);
    _stringContentCache[id] = result;
    return result;
  }

  @override
  void writeAsString(
    AssetId id,
    String contents, {
    Encoding encoding = utf8,
    required void Function() writer,
  }) {
    // Encodings other than utf8 do not use `_stringContentCache`.
    if (encoding == utf8) {
      _stringContentCache[id] = contents;
    } else {
      _stringContentCache.remove(id);
    }
    final bytes = encoding.encode(contents);
    _writeBytes(id, bytes, writer: writer);
  }

  @override
  void delete(AssetId id, {required void Function() deleter}) {
    _stringContentCache.remove(id);
    _bytesContentCache.remove(id);
    _existsCache[id] = false;
    _pendingWrites[id] = _PendingWrite(writer: deleter);
  }
}

/// The data that will be written on flush; used for reads before flush.
class _PendingWrite {
  final void Function() writer;
  final Uint8List? bytes;

  _PendingWrite({required this.writer, this.bytes});

  bool get isDelete => bytes == null;
}
