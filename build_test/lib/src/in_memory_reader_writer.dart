// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:build/build.dart';
// ignore: implementation_imports
import 'package:build/src/internal.dart';
// ignore: implementation_imports
import 'package:build_runner_core/src/asset/reader_writer.dart';
// ignore: implementation_imports
import 'package:build_runner_core/src/generate/input_tracker.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;
import 'package:watcher/watcher.dart';

import 'fake_watcher.dart';
import 'test_reader_writer.dart';

/// The implementation behind [TestReaderWriter].
///
/// It exposes `build_runner` internals and should not be used directly outside
/// this package.
class InMemoryAssetReaderWriter extends ReaderWriter
    implements TestReaderWriter {
  /// Assets read directly from this reader/writer.
  final Set<AssetId> assetsRead;

  /// Assets written directly to this reader/writer.
  final Set<AssetId> assetsWritten;

  final StreamController<AssetId> onCanReadController;

  /// Create a new asset reader/writer.
  ///
  /// If provided [rootPackage] is the default package when globbing for files.
  factory InMemoryAssetReaderWriter({String? rootPackage}) {
    final filesystem = InMemoryFilesystem();
    return InMemoryAssetReaderWriter.using(
      assetsRead: {},
      assetsWritten: {},
      rootPackage: rootPackage ?? 'unset',
      assetFinder: InMemoryAssetFinder(filesystem, rootPackage),
      assetPathProvider: const InMemoryAssetPathProvider(),
      generatedAssetHider: const NoopGeneratedAssetHider(),
      filesystem: filesystem,
      cache: const PassthroughFilesystemCache(),
      onDelete: null,
      onCanReadController: StreamController(),
    );
  }

  InMemoryAssetReaderWriter.using({
    required this.assetsRead,
    required this.assetsWritten,
    required super.rootPackage,
    required super.assetFinder,
    required super.assetPathProvider,
    required super.generatedAssetHider,
    required super.filesystem,
    required super.cache,
    required super.onDelete,
    required this.onCanReadController,
  }) : super.using() {
    InputTracker.captureInputTrackersForTesting = true;
  }

  @override
  InMemoryAssetReaderWriter copyWith({
    FilesystemCache? cache,
    GeneratedAssetHider? generatedAssetHider,
    void Function(AssetId)? onDelete,
  }) => InMemoryAssetReaderWriter.using(
    assetsRead: assetsRead,
    assetsWritten: assetsWritten,
    rootPackage: rootPackage,
    assetFinder: assetFinder,
    assetPathProvider: assetPathProvider,
    generatedAssetHider: generatedAssetHider ?? this.generatedAssetHider,
    filesystem: filesystem,
    cache: cache ?? this.cache,
    onDelete: onDelete ?? this.onDelete,
    onCanReadController: onCanReadController,
  );

  @override
  ReaderWriterTesting get testing => _ReaderWriterTestingImpl(this);

  @override
  Future<bool> canRead(AssetId id) {
    onCanReadController.add(id);
    assetsRead.add(id);
    return super.canRead(id);
  }

  /// Emits an event when `canRead` is called.
  ///
  /// This is used by internal `build_runner` tests and not exposed via the
  /// public `build_test` APIs.
  Stream<AssetId> get onCanRead => onCanReadController.stream;

  @override
  Future<List<int>> readAsBytes(AssetId id) async {
    assetsRead.add(id);
    return super.readAsBytes(id);
  }

  @override
  Future<String> readAsString(AssetId id, {Encoding encoding = utf8}) {
    assetsRead.add(id);
    return super.readAsString(id, encoding: encoding);
  }

  @override
  Future writeAsBytes(AssetId id, List<int> bytes) async {
    assetsWritten.add(id);
    var type = testing.exists(id) ? ChangeType.MODIFY : ChangeType.ADD;
    await super.writeAsBytes(id, bytes);
    FakeWatcher.notifyWatchers(
      WatchEvent(type, p.absolute(id.package, p.fromUri(id.path))),
    );
  }

  @override
  Future writeAsString(
    AssetId id,
    String contents, {
    Encoding encoding = utf8,
  }) async {
    assetsWritten.add(id);
    var type = testing.exists(id) ? ChangeType.MODIFY : ChangeType.ADD;
    await super.writeAsString(id, contents, encoding: encoding);
    FakeWatcher.notifyWatchers(
      WatchEvent(type, p.absolute(id.package, p.fromUri(id.path))),
    );
  }

  @override
  Future<void> delete(AssetId id) {
    onDelete?.call(id);
    FakeWatcher.notifyWatchers(
      WatchEvent(ChangeType.REMOVE, p.absolute(id.package, p.fromUri(id.path))),
    );
    return super.delete(id);
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
  Iterable<AssetId> get inputsTracked =>
      InputTracker.inputTrackersForTesting[_readerWriter.filesystem]!
          .expand((tracker) => tracker.inputs)
          .toSet();

  @override
  Iterable<AssetId> get resolverEntrypointsTracked =>
      InputTracker.inputTrackersForTesting[_readerWriter.filesystem]!
          .expand((tracker) => tracker.resolverEntrypoints)
          .toSet();

  @override
  Iterable<AssetId> get assetsRead => _readerWriter.assetsRead;

  @override
  Iterable<AssetId> get assetsWritten => _readerWriter.assetsWritten;

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
