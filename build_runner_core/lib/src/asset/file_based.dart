// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:build/build.dart';
// ignore: implementation_imports
import 'package:build/src/internal.dart';
import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';
import 'package:path/path.dart' as path;

import '../package_graph/package_graph.dart';
import 'writer.dart';

/// Basic [AssetReader] which uses a [PackageGraph] to look up where to read
/// files from disk.
class FileBasedAssetReader extends AssetReader implements AssetReaderState {
  @override
  final AssetPathProvider assetPathProvider;
  @override
  final Filesystem filesystem;
  @override
  late final AssetFinder assetFinder = FunctionAssetFinder(_findAssets);
  @override
  final FilesystemCache cache;

  final PackageGraph packageGraph;

  FileBasedAssetReader(
    this.packageGraph, {
    Filesystem? filesystem,
    FilesystemCache? cache,
  }) : filesystem = filesystem ?? IoFilesystem(),
       cache = cache ?? const PassthroughFilesystemCache(),
       assetPathProvider = packageGraph;

  @override
  FileBasedAssetReader copyWith({FilesystemCache? cache}) =>
      FileBasedAssetReader(packageGraph, filesystem: filesystem, cache: cache);

  @override
  InputTracker? get inputTracker => null;

  @override
  Future<bool> canRead(AssetId id) {
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
    return cache.readAsBytes(
      id,
      ifAbsent: () async {
        final path = assetPathProvider.pathFor(id);
        if (!await filesystem.exists(path)) {
          // TODO(davidmorgan): report the path as well?
          throw AssetNotFoundException(id);
        }
        return filesystem.readAsBytes(path);
      },
    );
  }

  @override
  Future<String> readAsString(AssetId id, {Encoding encoding = utf8}) async {
    return cache.readAsString(
      id,
      encoding: encoding,
      ifAbsent: () async {
        final path = assetPathProvider.pathFor(id);
        if (!await filesystem.exists(path)) {
          throw AssetNotFoundException(id);
        }
        return filesystem.readAsBytes(path);
      },
    );
  }

  // This is only for generators, so only `BuildStep` needs to implement it.
  @override
  Stream<AssetId> findAssets(Glob glob) => throw UnimplementedError();

  Stream<AssetId> _findAssets(Glob glob, String? package) {
    var packageNode =
        package == null ? packageGraph.root : packageGraph[package];
    if (packageNode == null) {
      throw ArgumentError(
        "Could not find package '$package' which was listed as "
        'an input. Please ensure you have that package in your deps, or '
        'remove it from your input sets.',
      );
    }
    // TODO(davidmorgan): make this read via `filesystem`, currently it
    // reads directly via `dart:io`.
    return glob
        .list(followLinks: true, root: packageNode.path)
        .where((e) => e is File && !path.basename(e.path).startsWith('._'))
        .cast<File>()
        .map((file) => _fileToAssetId(file, packageNode));
  }

  /// Creates an [AssetId] for [file], which is a part of [packageNode].
  AssetId _fileToAssetId(File file, PackageNode packageNode) {
    var filePath = path.normalize(file.absolute.path);
    var relativePath = path.relative(filePath, from: packageNode.path);
    return AssetId(packageNode.name, relativePath);
  }
}

/// Basic [AssetWriter] which uses a [PackageGraph] to look up where to write
/// files to disk.
class FileBasedAssetWriter implements RunnerAssetWriter {
  final PackageGraph packageGraph;
  final Filesystem filesystem;

  FileBasedAssetWriter(this.packageGraph) : filesystem = IoFilesystem();

  @override
  Future<void> writeAsBytes(AssetId id, List<int> bytes) async {
    final path = packageGraph.pathFor(id);
    await filesystem.writeAsBytes(path, bytes);
  }

  @override
  Future<void> writeAsString(
    AssetId id,
    String contents, {
    Encoding encoding = utf8,
  }) async {
    final path = packageGraph.pathFor(id);
    await filesystem.writeAsString(path, contents, encoding: encoding);
  }

  @override
  Future delete(AssetId id) async {
    if (id.package != packageGraph.root.name) {
      throw InvalidOutputException(
        id,
        'Should not delete assets outside of ${packageGraph.root.name}',
      );
    }
    final path = packageGraph.pathFor(id);
    await filesystem.delete(path);
  }

  @override
  Future<void> completeBuild() async {}
}
