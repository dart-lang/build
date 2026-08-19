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
      buildFileLayout: InMemoryBuildFileLayout(outputRootPackage ?? 'unset'),
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
    required super.buildFileLayout,
    required this.buildCachePackage,
    required super.filesystem,
    required this.onCanReadController,
    super.forceVisibleForTesting = false,
  }) : super.using() {
    InputTracker.captureInputTrackersForTesting = true;
  }

  InternalTestReaderWriter copyWith({bool? forceVisibleForTesting}) =>
      InternalTestReaderWriter.using(
        assetsRead: assetsRead,
        assetsWritten: assetsWritten,
        assetFinder: assetFinder,
        buildFileLayout: buildFileLayout,
        buildCachePackage: buildCachePackage,
        filesystem: filesystem,
        onCanReadController: onCanReadController,
        forceVisibleForTesting:
            forceVisibleForTesting ?? this.forceVisibleForTesting,
      );

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
  Future<void> writeFileAsBytes(BuildFile file, List<int> bytes) async {
    if (file is AssetFile) {
      assetsWritten.add(file.id);
    }
    final type = testing.existsFile(file) ? ChangeType.MODIFY : ChangeType.ADD;
    await super.writeFileAsBytes(file, bytes);
    final pkg = file is AssetFile
        ? file.id.package
        : (file as InternalFile).package;
    final path = file is AssetFile ? file.id.path : (file as InternalFile).path;
    FakeWatcher.notifyWatchers(
      WatchEvent(type, p.absolute(pkg, p.fromUri(path))),
    );
  }

  @override
  Future<void> writeFileAsString(
    BuildFile file,
    String contents, {
    Encoding encoding = utf8,
  }) async {
    if (file is AssetFile) {
      assetsWritten.add(file.id);
    }
    final type = testing.existsFile(file) ? ChangeType.MODIFY : ChangeType.ADD;
    await super.writeFileAsString(file, contents, encoding: encoding);
    final pkg = file is AssetFile
        ? file.id.package
        : (file as InternalFile).package;
    final path = file is AssetFile ? file.id.path : (file as InternalFile).path;
    FakeWatcher.notifyWatchers(
      WatchEvent(type, p.absolute(pkg, p.fromUri(path))),
    );
  }

  @override
  Future<void> deleteFile(BuildFile file) {
    final pkg = file is AssetFile
        ? file.id.package
        : (file as InternalFile).package;
    final path = file is AssetFile ? file.id.path : (file as InternalFile).path;
    FakeWatcher.notifyWatchers(
      WatchEvent(ChangeType.REMOVE, p.absolute(pkg, p.fromUri(path))),
    );
    return super.deleteFile(file);
  }
}

class InMemoryBuildFileLayout implements BuildFileLayout {
  final String outputRootPackage;

  InMemoryBuildFileLayout(this.outputRootPackage);

  @override
  String pathFor(BuildFile file, {bool checkWriteAllowed = false}) {
    if (file is AssetFile) {
      if (file.hidden) {
        return '$outputRootPackage|$generatedOutputDirectory/${file.id.package}/${file.id.path}';
      }
      return file.id.toString();
    } else if (file is InternalFile) {
      return '${file.package}|${file.path}';
    }
    throw ArgumentError('Unknown BuildFile type: $file');
  }

  @override
  BuildFile fromPath(BuildPackage package, String path) {
    return BuildFileLayout.fileFromPath(package, path);
  }
}

class InMemoryAssetFinder implements AssetFinder {
  final InMemoryFilesystem filesystem;

  InMemoryAssetFinder(this.filesystem);

  @override
  Stream<AssetId> find(Glob glob, {required String package}) {
    return Stream.fromIterable(
      filesystem.filePaths
          .where((path) {
            final pipeIndex = path.indexOf('|');
            if (pipeIndex == -1) return false;
            final pkg = path.substring(0, pipeIndex);
            final assetPath = path.substring(pipeIndex + 1);
            if (pkg != package) return false;
            if (assetPath.startsWith('.dart_tool/')) return false;
            return glob.matches(assetPath);
          })
          .map(AssetId.parse),
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
      (_readerWriter.filesystem as InMemoryFilesystem).filePaths
          .where((path) => !path.contains('.dart_tool/'))
          .map(AssetId.parse);

  @override
  Iterable<AssetId> get hiddenAssets =>
      (_readerWriter.filesystem as InMemoryFilesystem).filePaths
          .where((path) => path.contains('$generatedOutputDirectory/'))
          .map((path) {
            final prefix = '$generatedOutputDirectory/';
            final idx = path.indexOf(prefix);
            final sub = path.substring(idx + prefix.length);
            final firstSlash = sub.indexOf('/');
            if (firstSlash == -1) return null;
            final package = sub.substring(0, firstSlash);
            final relPath = sub.substring(firstSlash + 1);
            return AssetId(package, relPath);
          })
          .whereType<AssetId>();

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
  bool exists(AssetId id, {bool hidden = false}) =>
      existsFile(AssetFile(id, hidden: hidden));

  @override
  void writeString(AssetId id, String contents, {bool hidden = false}) =>
      writeFileString(AssetFile(id, hidden: hidden), contents);

  @override
  void writeBytes(AssetId id, List<int> contents, {bool hidden = false}) =>
      writeFileBytes(AssetFile(id, hidden: hidden), contents);

  @override
  Uint8List readBytes(AssetId id, {bool hidden = false}) =>
      readFileBytes(AssetFile(id, hidden: hidden));

  @override
  String readString(AssetId id, {bool hidden = false}) =>
      readFileString(AssetFile(id, hidden: hidden));

  @override
  void delete(AssetId id, {bool hidden = false}) =>
      deleteFile(AssetFile(id, hidden: hidden));

  @override
  bool existsFile(BuildFile file) => _readerWriter.filesystem.existsSync(
    _readerWriter.buildFileLayout.pathFor(file),
  );

  @override
  void writeFileString(BuildFile file, String contents) => _readerWriter
      .filesystem
      .writeAsStringSync(_readerWriter.buildFileLayout.pathFor(file), contents);

  @override
  void writeFileBytes(BuildFile file, List<int> contents) => _readerWriter
      .filesystem
      .writeAsBytesSync(_readerWriter.buildFileLayout.pathFor(file), contents);

  @override
  Uint8List readFileBytes(BuildFile file) => _readerWriter.filesystem
      .readAsBytesSync(_readerWriter.buildFileLayout.pathFor(file));

  @override
  String readFileString(BuildFile file) => _readerWriter.filesystem
      .readAsStringSync(_readerWriter.buildFileLayout.pathFor(file));

  @override
  void deleteFile(BuildFile file) => _readerWriter.filesystem.deleteSync(
    _readerWriter.buildFileLayout.pathFor(file),
  );
}
