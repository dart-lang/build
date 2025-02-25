// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:convert';
import 'dart:typed_data';

import 'package:build/build.dart';
// ignore: implementation_imports
import 'package:build/src/internal.dart';
// ignore: implementation_imports
import 'package:build_runner_core/src/asset/reader_writer.dart';
import 'package:glob/glob.dart';

import 'test_reader_writer.dart';

/// The implementation behind [TestReaderWriter].
///
/// It exposes `build_runner` internals and should not be used directly outside
/// this package.
class InMemoryAssetReaderWriter extends ReaderWriter
    implements TestReaderWriter {
  /// Create a new asset reader/writer.
  ///
  /// If provided [rootPackage] is the default package when globbing for files.
  ///
  /// Unlike the non-test [ReaderWriter], starts with an [inputTracker] so
  /// inputs can be inspected after the test runs.
  factory InMemoryAssetReaderWriter({String? rootPackage}) {
    final filesystem = InMemoryFilesystem();
    return InMemoryAssetReaderWriter.using(
      rootPackage: rootPackage ?? 'unset',
      assetFinder: InMemoryAssetFinder(filesystem, rootPackage),
      assetPathProvider: const InMemoryAssetPathProvider(),
      filesystem: filesystem,
      cache: const PassthroughFilesystemCache(),
      inputTracker: InputTracker(),
    );
  }

  InMemoryAssetReaderWriter.using({
    required super.rootPackage,
    required super.assetFinder,
    required super.assetPathProvider,
    required super.filesystem,
    required super.cache,
    required super.inputTracker,
  }) : super.using();

  @override
  InMemoryAssetReaderWriter copyWith({
    AssetPathProvider? assetPathProvider,
    FilesystemCache? cache,
  }) => InMemoryAssetReaderWriter.using(
    rootPackage: rootPackage,
    assetFinder: assetFinder,
    assetPathProvider: assetPathProvider ?? this.assetPathProvider,
    filesystem: filesystem,
    cache: cache ?? this.cache,
    inputTracker: inputTracker,
  );

  @override
  ReaderWriterTesting get testing => _ReaderWriterTestingImpl(this);

  // Record all reads in `inputTracker` so tests can verify them.
  //
  // TODO(davidmorgan): refactor to remove differences in how test and real
  // code use inputTracker; keep tracking for tests separate from real tracking.

  @override
  Future<bool> canRead(AssetId id) {
    inputTracker!.assetsRead.add(id);
    return super.canRead(id);
  }

  @override
  Future<List<int>> readAsBytes(AssetId id) async {
    inputTracker!.assetsRead.add(id);
    return super.readAsBytes(id);
  }

  @override
  Future<String> readAsString(AssetId id, {Encoding encoding = utf8}) async {
    inputTracker!.assetsRead.add(id);
    return super.readAsString(id, encoding: encoding);
  }
}

class InMemoryAssetPathProvider implements AssetPathProvider {
  const InMemoryAssetPathProvider();

  @override
  String pathFor(AssetId id) => id.toString();
}

class InMemoryAssetFinder implements AssetFinder {
  final InMemoryFilesystem filesystem;
  final String? rootPackage;

  InMemoryAssetFinder(this.filesystem, this.rootPackage);

  @override
  Stream<AssetId> find(Glob glob, {String? package}) {
    package ??= rootPackage;
    if (package == null) {
      throw UnsupportedError(
        'Root package is required to use findAssets without providing an '
        'explicit package.',
      );
    }
    return Stream.fromIterable(
      filesystem.filePaths
          .map(AssetId.parse)
          .where((id) => id.package == package && glob.matches(id.path)),
    );
  }
}

class _ReaderWriterTestingImpl implements ReaderWriterTesting {
  final InMemoryAssetReaderWriter _readerWriter;

  _ReaderWriterTestingImpl(this._readerWriter);

  @override
  Iterable<AssetId> get assets =>
      (_readerWriter.filesystem as InMemoryFilesystem).filePaths.map(
        AssetId.parse,
      );

  @override
  Iterable<AssetId> get assetsRead => _readerWriter.inputTracker!.assetsRead;

  @override
  bool exists(AssetId id) => _readerWriter.filesystem.existsSync(
    _readerWriter.assetPathProvider.pathFor(id),
  );

  @override
  void writeString(AssetId id, String contents) => _readerWriter.filesystem
      .writeAsStringSync(_readerWriter.assetPathProvider.pathFor(id), contents);

  @override
  void writeBytes(AssetId id, List<int> contents) => _readerWriter.filesystem
      .writeAsBytesSync(_readerWriter.assetPathProvider.pathFor(id), contents);

  @override
  Uint8List readBytes(AssetId id) => _readerWriter.filesystem.readAsBytesSync(
    _readerWriter.assetPathProvider.pathFor(id),
  );

  @override
  String readString(AssetId id) => _readerWriter.filesystem.readAsStringSync(
    _readerWriter.assetPathProvider.pathFor(id),
  );

  @override
  void delete(AssetId id) => _readerWriter.filesystem.deleteSync(
    _readerWriter.assetPathProvider.pathFor(id),
  );
}
