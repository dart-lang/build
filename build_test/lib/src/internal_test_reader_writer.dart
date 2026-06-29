// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:build/build.dart';
// ignore: implementation_imports
import 'package:build_runner/src/internal.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;
import 'package:watcher/watcher.dart';

import 'fake_watcher.dart';
import 'package_reader.dart';
import 'test_reader_writer.dart';

/// The implementation behind [TestReaderWriter].
///
/// It exposes `build_runner` internals and so is only for use in `build_test`
/// and `build_runner`.
class InternalTestReaderWriter extends ReaderWriter
    implements TestReaderWriter {
  final String buildCachePackage;

  /// Assets read directly from this reader/writer.
  final Set<AssetId> assetsRead;

  /// Assets written directly to this reader/writer.
  final Set<AssetId> assetsWritten;

  final StreamController<AssetId> onCanReadController;

  /// Create a new asset reader/writer.
  ///
  /// If provided [outputRootPackage] is the package where the build cache is
  /// written, otherwise `unset` is used.
  factory InternalTestReaderWriter({
    String? outputRootPackage,
    bool forceVisibleForTesting = false,
  }) {
    final filesystem = InMemoryFilesystem();
    return InternalTestReaderWriter.using(
      assetsRead: {},
      assetsWritten: {},
      assetFinder: InMemoryAssetFinder(filesystem),
      assetPathProvider: InMemoryAssetPathProvider(
        outputRootPackage ?? 'unset',
      ),
      buildCachePackage: outputRootPackage ?? 'unset',
      filesystem: filesystem,
      onCanReadController: StreamController(),
      forceVisibleForTesting: forceVisibleForTesting,
    );
  }

  InternalTestReaderWriter.using({
    required this.assetsRead,
    required this.assetsWritten,
    required super.assetFinder,
    required super.assetPathProvider,
    required this.buildCachePackage,
    required super.filesystem,
    required this.onCanReadController,
    super.forceVisibleForTesting = false,
  }) : super.using() {
    InputTracker.captureInputTrackersForTesting = true;
  }

  @override
  ReaderWriterTesting get testing => _ReaderWriterTestingImpl(this);

  @override
  Future<bool> canRead(AssetId id, {bool hidden = false}) {
    onCanReadController.add(id);
    assetsRead.add(id);
    return super.canRead(id, hidden: hidden);
  }

  /// Emits an event when `canRead` is called.
  ///
  /// This is used by internal `build_runner` tests and not exposed via the
  /// public `build_test` APIs.
  Stream<AssetId> get onCanRead => onCanReadController.stream;

  @override
  Future<List<int>> readAsBytes(AssetId id, {bool hidden = false}) async {
    assetsRead.add(id);
    return super.readAsBytes(id, hidden: hidden);
  }

  @override
  Future<String> readAsString(
    AssetId id, {
    Encoding encoding = utf8,
    bool hidden = false,
  }) {
    assetsRead.add(id);
    return super.readAsString(id, encoding: encoding, hidden: hidden);
  }

  @override
  Future writeAsBytes(
    AssetId id,
    List<int> bytes, {
    bool hidden = false,
  }) async {
    assetsWritten.add(id);
    final type = testing.exists(id) ? ChangeType.MODIFY : ChangeType.ADD;
    await super.writeAsBytes(id, bytes, hidden: hidden);
    FakeWatcher.notifyWatchers(
      WatchEvent(type, p.absolute(id.package, p.fromUri(id.path))),
    );
  }

  @override
  Future writeAsString(
    AssetId id,
    String contents, {
    Encoding encoding = utf8,
    bool hidden = false,
  }) async {
    assetsWritten.add(id);
    final type = testing.exists(id) ? ChangeType.MODIFY : ChangeType.ADD;
    await super.writeAsString(id, contents, encoding: encoding, hidden: hidden);
    FakeWatcher.notifyWatchers(
      WatchEvent(type, p.absolute(id.package, p.fromUri(id.path))),
    );
  }

  @override
  Future<void> delete(
    AssetId id, {
    bool hidden = false,
    void Function(AssetId)? onDelete,
  }) {
    onDelete?.call(id);
    FakeWatcher.notifyWatchers(
      WatchEvent(ChangeType.REMOVE, p.absolute(id.package, p.fromUri(id.path))),
    );
    return super.delete(id, hidden: hidden, onDelete: onDelete);
  }
}

class InMemoryAssetPathProvider implements AssetPathProvider {
  final String outputRootPackage;

  InMemoryAssetPathProvider(this.outputRootPackage);

  @override
  String pathFor(
    AssetId id, {
    required bool hide,
    bool checkDeleteAllowed = false,
  }) {
    if (hide) {
      id = AssetPathProvider.hide(id, outputRootPackage);
    }
    return id.toString();
  }
}

class InMemoryAssetFinder implements AssetFinder {
  final InMemoryFilesystem filesystem;

  InMemoryAssetFinder(this.filesystem);

  @override
  Stream<AssetId> find(Glob glob, {required String package}) {
    return Stream.fromIterable(
      filesystem.filePaths
          .map(AssetId.parse)
          .where((id) => id.package == package && glob.matches(id.path)),
    );
  }
}

class _ReaderWriterTestingImpl implements ReaderWriterTesting {
  final InternalTestReaderWriter _readerWriter;

  _ReaderWriterTestingImpl(this._readerWriter);

  @override
  Future<void> loadIsolateSources() async {
    final reader = await PackageAssetReader.currentIsolate();
    for (final package in reader.packageConfig.packages) {
      await for (final id in reader.findAssets(
        Glob('**'),
        package: package.name,
      )) {
        // Write via `testing` so it's not tracked as a builder output.
        _readerWriter.testing.writeBytes(id, await reader.readAsBytes(id));
      }
    }
  }

  @override
  Iterable<AssetId> get assets =>
      (_readerWriter.filesystem as InMemoryFilesystem).filePaths.map(
        AssetId.parse,
      );

  @override
  Iterable<AssetId> get inputsTracked => InputTracker
      .inputTrackersForTesting[_readerWriter.filesystem]!
      .expand((tracker) => tracker.inputs)
      .toSet();

  @override
  Iterable<AssetId> inputsTrackedFor({
    AssetId? primaryInput,
    String? builderLabel,
  }) => InputTracker.inputTrackersForTesting[_readerWriter.filesystem]!
      .where((inputTracker) {
        return (primaryInput == null ||
                primaryInput == inputTracker.primaryInput) &&
            (builderLabel == null || builderLabel == inputTracker.builderLabel);
      })
      .expand((tracker) => tracker.inputs)
      .toSet();

  @override
  Iterable<AssetId> get resolverEntrypointsTracked => InputTracker
      .inputTrackersForTesting[_readerWriter.filesystem]!
      .expand((tracker) => tracker.resolverEntrypoints)
      .toSet();

  @override
  Iterable<AssetId> resolverEntrypointsTrackedFor({
    AssetId? primaryInput,
    String? builderLabel,
  }) => InputTracker.inputTrackersForTesting[_readerWriter.filesystem]!
      .where((inputTracker) {
        return (primaryInput == null ||
                primaryInput == inputTracker.primaryInput) &&
            (builderLabel == null || builderLabel == inputTracker.builderLabel);
      })
      .expand((tracker) => tracker.resolverEntrypoints)
      .toSet();

  @override
  Iterable<AssetId> get assetsRead => _readerWriter.assetsRead;

  @override
  Iterable<AssetId> get assetsWritten => _readerWriter.assetsWritten;

  @override
  bool exists(AssetId id) => _readerWriter.filesystem.existsSync(
    _readerWriter.assetPathProvider.pathFor(id, hide: false),
  );

  @override
  void writeString(AssetId id, String contents) =>
      _readerWriter.filesystem.writeAsStringSync(
        _readerWriter.assetPathProvider.pathFor(id, hide: false),
        contents,
      );

  @override
  void writeBytes(AssetId id, List<int> contents) =>
      _readerWriter.filesystem.writeAsBytesSync(
        _readerWriter.assetPathProvider.pathFor(id, hide: false),
        contents,
      );

  @override
  Uint8List readBytes(AssetId id) => _readerWriter.filesystem.readAsBytesSync(
    _readerWriter.assetPathProvider.pathFor(id, hide: false),
  );

  @override
  String readString(AssetId id) => _readerWriter.filesystem.readAsStringSync(
    _readerWriter.assetPathProvider.pathFor(id, hide: false),
  );

  @override
  void delete(AssetId id) => _readerWriter.filesystem.deleteSync(
    _readerWriter.assetPathProvider.pathFor(id, hide: false),
  );
}
