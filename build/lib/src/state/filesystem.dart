// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:pool/pool.dart';

import '../asset/id.dart';
import 'asset_path_provider.dart';
import 'filesystem_cache.dart';

/// The filesystem the build is running on.
///
/// Methods behave as the `dart:io` methods with the same names, with some
/// exceptions noted in the docs.
///
/// Some methods cache, all uses of the cache are noted in the docs.
///
/// The cache might be a [PassthroughFilesystemCache] in which case it has no
/// effect.
///
/// TODO(davidmorgan): extend caching to sync methods, deletes, writes.
abstract interface class Filesystem {
  FilesystemCache get cache;

  /// Returns a new instance with optionally updated [cache].
  Filesystem copyWith({FilesystemCache? cache});

  /// Whether the file exists.
  ///
  /// Uses [cache].
  Future<bool> exists(AssetId id);

  /// Reads a file as a string.
  ///
  /// Uses [cache]. For `utf8`, the `String` is cached; for any other encoding
  /// the bytes are cached but the conversion runs on every read.
  Future<String> readAsString(AssetId id, {Encoding encoding = utf8});

  /// Reads a file as bytes.
  ///
  /// Uses [cache].
  Future<Uint8List> readAsBytes(AssetId id);

  /// Deletes a file.
  ///
  /// If the file does not exist, does nothing.
  Future<void> delete(AssetId id);

  /// Deletes a file.
  ///
  /// If the file does not exist, does nothing.
  void deleteSync(AssetId id);

  /// Writes a file.
  ///
  /// Creates enclosing directories as needed if they don't exist.
  void writeAsStringSync(
    AssetId id,
    String contents, {
    Encoding encoding = utf8,
  });

  /// Writes a file.
  ///
  /// Creates enclosing directories as needed if they don't exist.
  Future<void> writeAsString(
    AssetId id,
    String contents, {
    Encoding encoding = utf8,
  });

  /// Writes a file.
  ///
  /// Creates enclosing directories as needed if they don't exist.
  void writeAsBytesSync(AssetId id, List<int> contents);

  /// Writes a file.
  ///
  /// Creates enclosing directories as needed if they don't exist.
  Future<void> writeAsBytes(AssetId id, List<int> contents);
}

/// A filesystem using [assetPathProvider] to map to the `dart:io` filesystem.
class IoFilesystem implements Filesystem {
  @override
  final FilesystemCache cache;

  final AssetPathProvider assetPathProvider;

  /// Pool for async file operations.
  final _pool = Pool(32);

  IoFilesystem({
    required this.assetPathProvider,
    this.cache = const PassthroughFilesystemCache(),
  });

  @override
  IoFilesystem copyWith({FilesystemCache? cache}) => IoFilesystem(
    assetPathProvider: assetPathProvider,
    cache: cache ?? this.cache,
  );

  @override
  Future<bool> exists(AssetId id) =>
      cache.exists(id, ifAbsent: () => _pool.withResource(_fileFor(id).exists));

  @override
  Future<Uint8List> readAsBytes(AssetId id) => cache.readAsBytes(
    id,
    ifAbsent: () => _pool.withResource(_fileFor(id).readAsBytes),
  );

  @override
  Future<String> readAsString(AssetId id, {Encoding encoding = utf8}) async {
    // The cache only directly supports utf8, for other encodings get the
    // bytes via the cache then convert.
    if (encoding == utf8) {
      return cache.readAsString(
        id,
        ifAbsent: () => _pool.withResource(_fileFor(id).readAsString),
      );
    } else {
      return encoding.decode(await readAsBytes(id));
    }
  }

  @override
  void deleteSync(AssetId id) {
    final file = _fileFor(id);
    if (file.existsSync()) file.deleteSync();
  }

  @override
  Future<void> delete(AssetId id) {
    return _pool.withResource(() async {
      final file = _fileFor(id);
      if (await file.exists()) await file.delete();
    });
  }

  @override
  void writeAsBytesSync(
    AssetId id,
    List<int> contents, {
    Encoding encoding = utf8,
  }) {
    final file = _fileFor(id);
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(contents);
  }

  @override
  Future<void> writeAsBytes(AssetId id, List<int> contents) {
    return _pool.withResource(() async {
      final file = _fileFor(id);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(contents);
    });
  }

  @override
  void writeAsStringSync(
    AssetId id,
    String contents, {
    Encoding encoding = utf8,
  }) {
    final file = _fileFor(id);
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(contents, encoding: encoding);
  }

  @override
  Future<void> writeAsString(
    AssetId id,
    String contents, {
    Encoding encoding = utf8,
  }) {
    return _pool.withResource(() async {
      final file = _fileFor(id);
      await file.parent.create(recursive: true);
      await file.writeAsString(contents, encoding: encoding);
    });
  }

  /// Returns a [File] for [id] for the current [assetPathProvider].
  File _fileFor(AssetId id) {
    return File(assetPathProvider.pathFor(id));
  }
}

/// An in-memory [Filesystem].
class InMemoryFilesystem implements Filesystem {
  @override
  FilesystemCache cache;

  final Map<AssetId, List<int>> assets;

  InMemoryFilesystem({FilesystemCache? cache})
    : cache = cache ?? const PassthroughFilesystemCache(),
      assets = {};

  InMemoryFilesystem._({required this.cache, required this.assets});

  @override
  InMemoryFilesystem copyWith({FilesystemCache? cache}) =>
      InMemoryFilesystem._(assets: assets, cache: cache ?? this.cache);

  @override
  Future<bool> exists(AssetId id) async =>
      cache.exists(id, ifAbsent: () async => assets.containsKey(id));

  @override
  Future<Uint8List> readAsBytes(AssetId id) async =>
      cache.readAsBytes(id, ifAbsent: () async => assets[id] as Uint8List);

  @override
  Future<String> readAsString(AssetId id, {Encoding encoding = utf8}) async {
    // The cache only directly supports utf8, for other encodings get the
    // bytes via the cache then convert.
    if (encoding == utf8) {
      return cache.readAsString(
        id,
        ifAbsent: () async => encoding.decode(assets[id]!),
      );
    } else {
      return encoding.decode(await readAsBytes(id));
    }
  }

  @override
  Future<void> delete(AssetId id) async {
    assets.remove(id);
  }

  @override
  void deleteSync(AssetId id) async {
    assets.remove(id);
  }

  @override
  void writeAsBytesSync(AssetId id, List<int> contents) {
    assets[id] = contents;
  }

  @override
  Future<void> writeAsBytes(AssetId id, List<int> contents) async {
    assets[id] = contents;
  }

  @override
  void writeAsStringSync(
    AssetId id,
    String contents, {
    Encoding encoding = utf8,
  }) {
    assets[id] = encoding.encode(contents);
  }

  @override
  Future<void> writeAsString(
    AssetId id,
    String contents, {
    Encoding encoding = utf8,
  }) async {
    assets[id] = encoding.encode(contents);
  }
}
