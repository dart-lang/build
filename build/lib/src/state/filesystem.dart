// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// The filesystem the build is running on.
///
/// Methods behave as the `dart:io` methods with the same names, with some
/// exceptions noted in the docs.
abstract interface class Filesystem {
  /// Whether the file exists.
  Future<bool> exists(String path);

  /// Whether the file exists.
  bool existsSync(String path);

  /// Reads a file as a string.
  Future<String> readAsString(String path, {Encoding encoding = utf8});

  /// Reads a file as a string.
  String readAsStringSync(String path, {Encoding encoding = utf8});

  /// Reads a file as bytes.
  Future<Uint8List> readAsBytes(String path);

  /// Reads a file as bytes.
  Uint8List readAsBytesSync(String path);

  /// Deletes a file.
  ///
  /// If the file does not exist, does nothing.
  Future<void> delete(String path);

  /// Deletes a file.
  ///
  /// If the file does not exist, does nothing.
  void deleteSync(String path);

  /// Deletes a directory recursively.
  ///
  /// If the directory does not exist, does nothing.
  Future<void> deleteDirectory(String path);

  /// Writes a file.
  ///
  /// Creates enclosing directories as needed if they don't exist.
  void writeAsStringSync(
    String path,
    String contents, {
    Encoding encoding = utf8,
  });

  /// Writes a file.
  ///
  /// Creates enclosing directories as needed if they don't exist.
  Future<void> writeAsString(
    String path,
    String contents, {
    Encoding encoding = utf8,
  });

  /// Writes a file.
  ///
  /// Creates enclosing directories as needed if they don't exist.
  void writeAsBytesSync(String path, List<int> contents);

  /// Writes a file.
  ///
  /// Creates enclosing directories as needed if they don't exist.
  Future<void> writeAsBytes(String path, List<int> contents);
}

/// The `dart:io` filesystem.
class IoFilesystem implements Filesystem {
  @override
  Future<bool> exists(String path) => File(path).exists();

  @override
  bool existsSync(String path) => File(path).existsSync();

  @override
  Future<Uint8List> readAsBytes(String path) => File(path).readAsBytes();

  @override
  Uint8List readAsBytesSync(String path) => File(path).readAsBytesSync();

  @override
  Future<String> readAsString(String path, {Encoding encoding = utf8}) =>
      File(path).readAsString(encoding: encoding);

  @override
  String readAsStringSync(String path, {Encoding encoding = utf8}) =>
      File(path).readAsStringSync(encoding: encoding);

  @override
  void deleteSync(String path) {
    final file = File(path);
    if (file.existsSync()) file.deleteSync();
  }

  @override
  Future<void> delete(String path) async {
    final file = File(path);
    if (await file.exists()) await file.delete();
  }

  @override
  Future<void> deleteDirectory(String path) async {
    final directory = Directory(path);
    if (await directory.exists()) await directory.delete(recursive: true);
  }

  @override
  void writeAsBytesSync(
    String path,
    List<int> contents, {
    Encoding encoding = utf8,
  }) {
    final file = File(path);
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(contents);
  }

  @override
  Future<void> writeAsBytes(String path, List<int> contents) async {
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(contents);
  }

  @override
  void writeAsStringSync(
    String path,
    String contents, {
    Encoding encoding = utf8,
  }) {
    final file = File(path);
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(contents, encoding: encoding);
  }

  @override
  Future<void> writeAsString(
    String path,
    String contents, {
    Encoding encoding = utf8,
  }) async {
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsString(contents, encoding: encoding);
  }
}

/// An in-memory [Filesystem].
class InMemoryFilesystem implements Filesystem {
  final Map<String, Uint8List> _files = {};

  /// The paths to all files present on the filesystem.
  Iterable<String> get filePaths => _files.keys;

  @override
  Future<bool> exists(String path) => Future.value(_files.containsKey(path));

  @override
  bool existsSync(String path) => _files.containsKey(path);

  @override
  Future<Uint8List> readAsBytes(String path) => Future.value(_files[path]!);

  @override
  Uint8List readAsBytesSync(String path) => _files[path]!;

  @override
  Future<String> readAsString(String path, {Encoding encoding = utf8}) =>
      Future.value(encoding.decode(_files[path]!));

  @override
  String readAsStringSync(String path, {Encoding encoding = utf8}) =>
      encoding.decode(_files[path]!);

  @override
  Future<void> delete(String path) {
    _files.remove(path);
    return Future.value();
  }

  @override
  void deleteSync(String path) => _files.remove(path);

  @override
  Future<void> deleteDirectory(String path) {
    final prefix = '$path/';
    _files.removeWhere((filePath, _) => filePath.startsWith(prefix));
    return Future.value();
  }

  @override
  void writeAsBytesSync(String path, List<int> contents) {
    _files[path] = Uint8List.fromList(contents);
  }

  @override
  Future<void> writeAsBytes(String path, List<int> contents) {
    _files[path] = Uint8List.fromList(contents);
    return Future.value();
  }

  @override
  void writeAsStringSync(
    String path,
    String contents, {
    Encoding encoding = utf8,
  }) {
    _files[path] = Uint8List.fromList(encoding.encode(contents));
  }

  @override
  Future<void> writeAsString(
    String path,
    String contents, {
    Encoding encoding = utf8,
  }) {
    _files[path] = Uint8List.fromList(encoding.encode(contents));
    return Future.value();
  }
}
