// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:typed_data';

import 'package:build/build.dart';

import 'fake_watcher.dart';
import 'internal_test_reader_writer.dart';
import 'test_builder.dart' show testBuilders;

/// In-memory implementation of [AssetReader] and [AssetWriter].
///
/// [testing] provides a [ReaderWriterTesting] that gives access to the
/// in-memory filesystem for tests to directly modify files and check on
/// files.
///
/// Writes and deletes are notified to [FakeWatcher].
///
/// You must pass a `rootPackage` if the `TestReaderWriter` will be used in
/// a build. This specifies which package `build_runner` is running in.
///
/// On disk "hidden" assets are placed under `.dart_tool/build/generated/<package>`
/// while non-hidden assets are placed in the main source tree.
/// Some parts of this API are from the point of view of a builder and use a
/// unified namespace for [AssetId]s, while others see a split view
/// of the hidden/non-hidden filesystem structure, and require an explicit
/// mapping of [AssetId]s to the on-disk structure
/// (eg. starting with `.dart_tool/build/generated/`) to access hidden files.
/// See [testBuilders] `flattenOutput` parameter for more details.
abstract interface class TestReaderWriter implements AssetReader, AssetWriter {
  factory TestReaderWriter({String? rootPackage}) =>
      InternalTestReaderWriter(outputRootPackage: rootPackage);

  ReaderWriterTesting get testing;
}

/// Access to [TestReaderWriter] state for testing.
abstract interface class ReaderWriterTesting {
  /// Loads all `lib` files visible to the current isolate into memory.
  Future<void> loadIsolateSources();

  /// All the assets that exist on the [TestReaderWriter] in-memory filesystem.
  Iterable<AssetId> get assets;

  /// The assets that have been recorded as inputs of the build.
  Iterable<AssetId> get inputsTracked;

  /// The assets that have been recorded as inputs of the build, filtered to
  /// build steps for [primaryInput] and/or with [builderLabel].
  ///
  /// Builder labels are the builder names that appear in log output, for
  /// example `source_gen:combining_builder`.
  Iterable<AssetId> inputsTrackedFor({
    AssetId? primaryInput,
    String? builderLabel,
  });

  /// The assets that the build resolved using the analyzer.
  ///
  /// Only the entrypoints are recorded, but all sources reachable transitively
  /// via its directives will be treated as dependencies of the build for
  /// invalidation purposes.
  Iterable<AssetId> get resolverEntrypointsTracked;

  /// The assets that have been resolved using the analyzer, filtered to
  /// build steps for [primaryInput] and/or with [builderLabel].
  Iterable<AssetId> resolverEntrypointsTrackedFor({
    AssetId? primaryInput,
    String? builderLabel,
  });

  /// The assets that have been read via the [TestReaderWriter]'s non-test
  /// APIs.
  ///
  /// This differs from [inputsTracked] when the reader is not integrated
  /// with a build, for example when read methods are called directly on
  /// [TestReaderWriter]. Then, the assets are recorded in [assetsRead]
  /// but not in [inputsTracked].
  Iterable<AssetId> get assetsRead;

  /// The assets that have been written via the [TestReaderWriter]'s non-test
  /// APIs.
  Iterable<AssetId> get assetsWritten;

  /// Whether [id] exists on the [TestReaderWriter] in-memory filesystem.
  ///
  /// [AssetId]s are from the point of view of the filesystem,
  /// so "hidden" assets are under .dart_tool.
  /// See also [TestReaderWriter] class documentation and
  /// [testBuilders] `flattenOutput` parameter.
  bool exists(AssetId id);

  /// Writes [id] with [contents] to the [TestReaderWriter] in-memory
  /// filesystem.
  void writeString(AssetId id, String contents);

  /// Writes [id] with [contents] to the [TestReaderWriter] in-memory
  /// filesystem.
  void writeBytes(AssetId id, List<int> contents);

  /// Reads [id] from the [TestReaderWriter] in-memory filesystem.
  ///
  /// [AssetId]s are from the point of view of the filesystem,
  /// so "hidden" assets are under .dart_tool.
  /// See also [TestReaderWriter] class documentation and
  /// [testBuilders] `flattenOutput` parameter.
  Uint8List readBytes(AssetId id);

  /// Reads [id] from the [TestReaderWriter] in-memory filesystem.
  ///
  /// [AssetId]s are from the point of view of the filesystem,
  /// so "hidden" assets are under .dart_tool.
  /// /// See also [TestReaderWriter] class documentation and
  String readString(AssetId id);

  /// Deletes [id] from the [TestReaderWriter] in-memory filesystem.
  ///
  /// [AssetId]s are from the point of view of the filesystem,
  /// so "hidden" assets are under .dart_tool.
  /// /// [testBuilders] `flattenOutput` parameter.
  void delete(AssetId id);
}
