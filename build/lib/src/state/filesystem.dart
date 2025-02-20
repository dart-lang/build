// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:pool/pool.dart';

import '../asset/id.dart';
import 'asset_path_provider.dart';

/// The filesystem the build is running on.
///
/// Methods behave as the `dart:io` methods with the same names, with some
/// exceptions noted.
abstract interface class Filesystem {
  Future<bool> exists(AssetId id);

  Future<String> readAsString(AssetId id, {Encoding encoding = utf8});
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
  final AssetPathProvider assetPathProvider;

  /// Pool for async file operations.
  final _pool = Pool(32);

  IoFilesystem({required this.assetPathProvider});

  @override
  Future<bool> exists(AssetId id) => _pool.withResource(_fileFor(id).exists);

  @override
  Future<Uint8List> readAsBytes(AssetId id) =>
      _pool.withResource(_fileFor(id).readAsBytes);

  @override
  Future<String> readAsString(AssetId id, {Encoding encoding = utf8}) =>
      _pool.withResource(_fileFor(id).readAsString);

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
  final Map<AssetId, List<int>> assets = {};

  @override
  Future<bool> exists(AssetId id) async => assets.containsKey(id);

  @override
  Future<Uint8List> readAsBytes(AssetId id) async => assets[id] as Uint8List;

  @override
  Future<String> readAsString(AssetId id, {Encoding encoding = utf8}) async =>
      encoding.decode(assets[id] as Uint8List);

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
