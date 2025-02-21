// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:convert';
import 'dart:typed_data';

import 'package:build/build.dart';
// ignore: implementation_imports
import 'package:build/src/internal.dart';
import 'package:glob/glob.dart';

import 'test_reader_writer.dart';

/// The implementation behind [TestReaderWriter].
///
/// It exposes `build_runner` internals and should not be used directly outside
/// this package.
///
/// TODO(davidmorgan): merge into `FileBasedReader` and `FileBasedWriter`.
class InMemoryAssetReaderWriter extends AssetReader
    implements AssetReaderState, AssetWriter, TestReaderWriter {
  @override
  late final AssetFinder assetFinder = FunctionAssetFinder(_findAssets);

  @override
  final AssetPathProvider assetPathProvider;

  final InMemoryFilesystem _filesystem;

  @override
  final FilesystemCache cache;

  final String? rootPackage;

  @override
  final InputTracker inputTracker = InputTracker();

  /// Create a new asset reader/writer.
  ///
  /// May optionally define a [rootPackage], which is required for some APIs.
  InMemoryAssetReaderWriter({
    this.rootPackage,
    InMemoryFilesystem? filesystem,
    FilesystemCache? cache,
    AssetPathProvider? assetPathProvider,
  }) : _filesystem = filesystem ?? InMemoryFilesystem(),
       cache = cache ?? const PassthroughFilesystemCache(),
       assetPathProvider =
           assetPathProvider ?? const InMemoryAssetPathProvider();

  @override
  InMemoryAssetReaderWriter copyWith({FilesystemCache? cache}) =>
      InMemoryAssetReaderWriter(
        rootPackage: rootPackage,
        filesystem: _filesystem,
        cache: cache ?? this.cache,
      );

  @override
  ReaderWriterTesting get testing => _ReaderWriterTestingImpl(this);

  // Other methods.

  @override
  Filesystem get filesystem => _filesystem;

  @override
  Future<bool> canRead(AssetId id) async {
    inputTracker.assetsRead.add(id);
    return cache.exists(
      id,
      ifAbsent: () async {
        final path = assetPathProvider.pathFor(id);
        return filesystem.exists(path);
      },
    );
  }

  @override
  Future<List<int>> readAsBytes(AssetId id) async {
    if (!await canRead(id)) throw AssetNotFoundException(id);
    inputTracker.assetsRead.add(id);
    return cache.readAsBytes(
      id,
      ifAbsent: () async {
        final path = assetPathProvider.pathFor(id);
        return filesystem.readAsBytes(path);
      },
    );
  }

  @override
  Future<String> readAsString(AssetId id, {Encoding encoding = utf8}) async {
    if (!await canRead(id)) throw AssetNotFoundException(id);
    inputTracker.assetsRead.add(id);
    return cache.readAsString(
      id,
      encoding: encoding,
      ifAbsent: () async {
        final path = assetPathProvider.pathFor(id);
        return filesystem.readAsBytes(path);
      },
    );
  }

  // This is only for generators, so only `BuildStep` needs to implement it.
  @override
  Stream<AssetId> findAssets(Glob glob) => throw UnimplementedError();

  Stream<AssetId> _findAssets(Glob glob, String? package) {
    package ??= rootPackage;
    if (package == null) {
      throw UnsupportedError(
        'Root package is required to use findAssets without providing an '
        'explicit package.',
      );
    }
    return Stream.fromIterable(
      testing.assets.where(
        (id) => id.package == package && glob.matches(id.path),
      ),
    );
  }

  @override
  Future writeAsBytes(AssetId id, List<int> bytes) async =>
      filesystem.writeAsBytes(assetPathProvider.pathFor(id), bytes);

  @override
  Future writeAsString(
    AssetId id,
    String contents, {
    Encoding encoding = utf8,
  }) async => filesystem.writeAsString(
    assetPathProvider.pathFor(id),
    contents,
    encoding: encoding,
  );
}

class InMemoryAssetPathProvider implements AssetPathProvider {
  const InMemoryAssetPathProvider();

  @override
  String pathFor(AssetId id) => id.toString();
}

class _ReaderWriterTestingImpl implements ReaderWriterTesting {
  final InMemoryAssetReaderWriter _readerWriter;

  _ReaderWriterTestingImpl(this._readerWriter);

  @override
  Iterable<AssetId> get assets =>
      _readerWriter._filesystem.filePaths.map(AssetId.parse);

  @override
  Iterable<AssetId> get assetsRead => _readerWriter.inputTracker.assetsRead;

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
