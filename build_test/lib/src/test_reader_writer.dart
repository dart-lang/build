// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:typed_data';

import 'package:build/build.dart';

import 'in_memory_reader_writer.dart';

/// In-memory implementation of [AssetReader] and [AssetWriter].
///
/// [testing] provides a [ReaderWriterTesting] that gives access to the
/// in-memory filesystem for tests to directly modify files and check on
/// files.
abstract interface class TestReaderWriter implements AssetReader, AssetWriter {
  factory TestReaderWriter({String? rootPackage}) =>
      InMemoryAssetReaderWriter(rootPackage: rootPackage);

  ReaderWriterTesting get testing;
}

/// Access to [TestReaderWriter] state for testing.
abstract interface class ReaderWriterTesting {
  /// All the assets that exist on the [TestReaderWriter] in-memory filesystem.
  Iterable<AssetId> get assets;

  /// The assets that have been read via the [TestReaderWriter]'s non-test
  /// APIs.
  Iterable<AssetId> get assetsRead;

  /// Whether [id] exists on the [TestReaderWriter] in-memory filesystem.
  bool exists(AssetId id);

  /// Writes [id] with [contents] to the [TestReaderWriter] in-memory
  /// filesystem.
  void writeString(AssetId id, String contents);

  /// Writes [id] with [contents] to the [TestReaderWriter] in-memory
  /// filesystem.
  void writeBytes(AssetId id, List<int> contents);

  /// Reads [id] from the [TestReaderWriter] in-memory filesystem.
  Uint8List readBytes(AssetId id);

  /// Reads [id] from the [TestReaderWriter] in-memory filesystem.
  String readString(AssetId id);

  /// Deletes [id] from the [TestReaderWriter] in-memory filesystem.
  void delete(AssetId id);
}
