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
  bool existsSync(String path);

  /// Reads a file as a string.
  String readAsStringSync(String path, {Encoding encoding = utf8});

  /// Reads a file as bytes.
  Uint8List readAsBytesSync(String path);

  /// Deletes a file.
  ///
  /// If the file does not exist, does nothing.
  void deleteSync(String path);

  /// Deletes a directory recursively.
  ///
  /// If the directory does not exist, does nothing.
  void deleteDirectorySync(String path);

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
  void writeAsBytesSync(String path, List<int> contents);
}

/// The `dart:io` filesystem.
class IoFilesystem implements Filesystem {
  @override
  bool existsSync(String path) => File(path).existsSync();

  @override
  Uint8List readAsBytesSync(String path) => File(path).readAsBytesSync();

  @override
  String readAsStringSync(String path, {Encoding encoding = utf8}) =>
      File(path).readAsStringSync(encoding: encoding);

  @override
  void deleteSync(String path) {
    final file = File(path);
    if (file.existsSync()) file.deleteSync();
  }

  @override
  void deleteDirectorySync(String path) {
    final directory = Directory(path);
    if (directory.existsSync()) directory.deleteSync(recursive: true);
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
  void writeAsStringSync(
    String path,
    String contents, {
    Encoding encoding = utf8,
  }) {
    final file = File(path);
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(contents, encoding: encoding);
  }
}

/// An in-memory [Filesystem].
class InMemoryFilesystem implements Filesystem {
  final Map<String, Uint8List> _files = {};

  /// The paths to all files present on the filesystem.
  Iterable<String> get filePaths => _files.keys;

  @override
  bool existsSync(String path) => _files.containsKey(path);

  @override
  Uint8List readAsBytesSync(String path) => _files[path]!;

  @override
  String readAsStringSync(String path, {Encoding encoding = utf8}) =>
      encoding.decode(_files[path]!);

  @override
  void deleteSync(String path) => _files.remove(path);

  @override
  void deleteDirectorySync(String path) {
    final prefix = '$path/';
    _files.removeWhere((filePath, _) => filePath.startsWith(prefix));
  }

  @override
  void writeAsBytesSync(String path, List<int> contents) {
    _files[path] = Uint8List.fromList(contents);
  }

  @override
  void writeAsStringSync(
    String path,
    String contents, {
    Encoding encoding = utf8,
  }) {
    _files[path] = Uint8List.fromList(encoding.encode(contents));
  }
}
