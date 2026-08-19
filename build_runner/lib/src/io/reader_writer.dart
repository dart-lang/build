// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:build/build.dart';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';
import 'package:path/path.dart' as path;

import '../build_file.dart';
import '../build_file_layout.dart';
import '../build_plan/build_package.dart';
import '../build_plan/build_packages.dart';
import '../logging/timed_activities.dart';
import 'asset_finder.dart';
import 'filesystem.dart';

/// File operations during a build.
///
/// [AssetReader] and [AssetWriter] are the builder-facing file operations APIs,
/// and are implemented here so that `TestReaderWriter` can offer them.
///
/// Various methods accept `hidden`, which causes assets to be resolved under
/// `.dart_tool/build/generated` instead of in the source tree.
class ReaderWriter implements AssetReader, AssetWriter {
  final AssetFinder assetFinder;
  final BuildFileLayout buildFileLayout;
  final Filesystem filesystem;

  /// Whether to force `hidden` to false.
  ///
  /// Used only in tests.
  final bool forceVisibleForTesting;

  /// A [ReaderWriter] suitable for real builds.
  ///
  /// [buildPackages] is used for mapping paths and finding assets. The
  /// `dart-io` filesystem is used with no cache.
  factory ReaderWriter(
    BuildPackages buildPackages, {
    bool forceVisibleForTesting = false,
  }) => ReaderWriter.using(
    assetFinder: BuildPackagesAssetFinder(buildPackages),
    buildFileLayout: buildPackages,
    filesystem: IoFilesystem(),
    forceVisibleForTesting: forceVisibleForTesting,
  );

  ReaderWriter.using({
    required this.assetFinder,
    required this.buildFileLayout,
    required this.filesystem,
    this.forceVisibleForTesting = false,
  });

  String _pathFor(BuildFile file, {bool checkWriteAllowed = false}) {
    if (file is AssetFile && forceVisibleForTesting) {
      file = AssetFile.source(file.id);
    }
    return buildFileLayout.pathFor(file, checkWriteAllowed: checkWriteAllowed);
  }

  Future<bool> canReadFile(BuildFile file) {
    return Future.value(
      TimedActivity.read.run(() {
        final path = _pathFor(file);
        return filesystem.existsSync(path);
      }),
    );
  }

  @override
  Future<bool> canRead(AssetId id, {bool hidden = false}) =>
      canReadFile(AssetFile(id, hidden: hidden));

  Future<List<int>> readFileAsBytes(BuildFile file) {
    return Future.value(
      TimedActivity.read.run(() {
        final path = _pathFor(file);
        if (!filesystem.existsSync(path)) {
          throw file is AssetFile
              ? AssetNotFoundException(file.id, path: path)
              : FileSystemException('File not found', path);
        }
        return filesystem.readAsBytesSync(path);
      }),
    );
  }

  @override
  Future<List<int>> readAsBytes(AssetId id, {bool hidden = false}) =>
      readFileAsBytes(AssetFile(id, hidden: hidden));

  Future<String> readFileAsString(BuildFile file, {Encoding encoding = utf8}) {
    return Future.value(
      TimedActivity.read.run(() {
        final path = _pathFor(file);
        if (!filesystem.existsSync(path)) {
          throw file is AssetFile
              ? AssetNotFoundException(file.id, path: path)
              : FileSystemException('File not found', path);
        }
        return encoding.decode(filesystem.readAsBytesSync(path));
      }),
    );
  }

  @override
  Future<String> readAsString(
    AssetId id, {
    Encoding encoding = utf8,
    bool hidden = false,
  }) => readFileAsString(AssetFile(id, hidden: hidden), encoding: encoding);

  // [AssetWriter] methods.

  Future<void> writeFileAsBytes(BuildFile file, List<int> bytes) {
    TimedActivity.write.run(() {
      final path = _pathFor(file, checkWriteAllowed: true);
      filesystem.writeAsBytesSync(path, bytes);
    });
    return Future.value();
  }

  @override
  Future<void> writeAsBytes(
    AssetId id,
    List<int> bytes, {
    bool hidden = false,
  }) => writeFileAsBytes(AssetFile(id, hidden: hidden), bytes);

  Future<void> writeFileAsString(
    BuildFile file,
    String contents, {
    Encoding encoding = utf8,
  }) {
    TimedActivity.write.run(() {
      final path = _pathFor(file, checkWriteAllowed: true);
      filesystem.writeAsStringSync(path, contents, encoding: encoding);
    });
    return Future.value();
  }

  @override
  Future<void> writeAsString(
    AssetId id,
    String contents, {
    Encoding encoding = utf8,
    bool hidden = false,
  }) => writeFileAsString(
    AssetFile(id, hidden: hidden),
    contents,
    encoding: encoding,
  );

  @override
  Future<Digest> digest(AssetId id, {bool hidden = false}) async {
    final digestSink = AccumulatorSink<Digest>();
    md5.startChunkedConversion(digestSink)
      ..add(await readAsBytes(id, hidden: hidden))
      ..add(id.toString().codeUnits)
      ..close();
    return digestSink.events.first;
  }

  Future<void> deleteFile(BuildFile file) {
    TimedActivity.write.run(() {
      final path = _pathFor(file, checkWriteAllowed: true);
      filesystem.deleteSync(path);
    });
    return Future.value();
  }

  Future<void> delete(AssetId id, {bool hidden = false}) =>
      deleteFile(AssetFile(id, hidden: hidden));

  Future<void> deleteDirectoryFile(BuildFile file) {
    TimedActivity.write.run(() {
      final path = _pathFor(file, checkWriteAllowed: true);
      filesystem.deleteDirectorySync(path);
    });
    return Future.value();
  }

  Future<void> deleteDirectory(AssetId id, {bool hidden = false}) =>
      deleteDirectoryFile(AssetFile(id, hidden: hidden));

  // This is only for builders, so only `BuildStep` needs to implement it.
  @override
  Stream<AssetId> findAssets(Glob glob) => throw UnimplementedError();
}

/// [AssetFinder] that uses [BuildPackages] to map packages to paths, then
/// uses the `dart:io` filesystem to find files.
///
/// TODO(davidmorgan): read via `Filesystem` instead of `dart-io`.
class BuildPackagesAssetFinder implements AssetFinder {
  final BuildPackages buildPackages;

  BuildPackagesAssetFinder(this.buildPackages);

  @override
  Stream<AssetId> find(Glob glob, {required String package}) {
    final packageNode = buildPackages[package];
    if (packageNode == null) {
      throw ArgumentError(
        "Could not find package '$package' which was listed as "
        'an input. Please ensure you have that package in your deps, or '
        'remove it from your input sets.',
      );
    }
    return glob
        .list(followLinks: true, root: packageNode.path)
        .where((e) => e is File && !path.basename(e.path).startsWith('._'))
        .cast<File>()
        .where((file) {
          final filePath = path.normalize(file.absolute.path);
          final relativePath = path.relative(filePath, from: packageNode.path);
          return !relativePath.startsWith('.dart_tool/') &&
              relativePath != '.dart_tool';
        })
        .map((file) => _fileToAssetId(file, packageNode));
  }

  /// Creates an [AssetId] for [file], which is a part of [packageNode].
  static AssetId _fileToAssetId(File file, BuildPackage packageNode) {
    final filePath = path.normalize(file.absolute.path);
    final relativePath = path.relative(filePath, from: packageNode.path);
    return AssetId(packageNode.name, relativePath);
  }
}
