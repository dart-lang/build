// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as path;
import 'package:pool/pool.dart';

import '../package_graph/package_graph.dart';
import 'reader.dart';
import 'writer.dart';

/// Pool for async file operations, we don't want to use too many file handles.
final _descriptorPool = new Pool(32);

/// Basic [AssetReader] which uses a [PackageGraph] to look up where to read
/// files from disk.
class FileBasedAssetReader extends AssetReader implements RunnerAssetReader {
  final PackageGraph packageGraph;

  FileBasedAssetReader(this.packageGraph);

  @override
  Future<bool> canRead(AssetId id) =>
      _descriptorPool.withResource(() => _fileFor(id, packageGraph).exists());

  @override
  Future<List<int>> readAsBytes(AssetId id) => _fileForOrThrow(id, packageGraph)
      .then((file) => _descriptorPool.withResource(file.readAsBytes));

  @override
  Future<String> readAsString(AssetId id, {Encoding encoding}) =>
      _fileForOrThrow(id, packageGraph).then((file) => _descriptorPool
          .withResource(() => file.readAsString(encoding: encoding ?? utf8)));

  @override
  Stream<AssetId> findAssets(Glob glob, {String package}) async* {
    var packageNode =
        package == null ? packageGraph.root : packageGraph[package];
    if (packageNode == null) {
      throw new ArgumentError(
          "Could not find package '$package' which was listed as "
          'an input. Please ensure you have that package in your deps, or '
          'remove it from your input sets.');
    }
    var packagePath = packageNode.path;
    try {
      var fileStream = glob
          .list(followLinks: false, root: packagePath)
          .where((e) => e is File);
      await for (var file in fileStream) {
        // TODO(jakemac): Where do these files come from???
        if (path.basename(file.path).startsWith('._')) continue;
        yield _fileToAssetId(file as File, packageNode);
      }
    } on FileSystemException catch (_) {
      // Empty results
    }
  }
}

/// Creates an [AssetId] for [file], which is a part of [packageNode].
AssetId _fileToAssetId(File file, PackageNode packageNode) {
  var filePath = path.normalize(file.absolute.path);
  var relativePath = path.relative(filePath, from: packageNode.path);
  return new AssetId(packageNode.name, relativePath);
}

/// Basic [AssetWriter] which uses a [PackageGraph] to look up where to write
/// files to disk.
class FileBasedAssetWriter implements RunnerAssetWriter {
  final PackageGraph packageGraph;

  FileBasedAssetWriter(this.packageGraph);

  @override
  Future writeAsBytes(AssetId id, List<int> bytes) async {
    var file = _fileFor(id, packageGraph);
    await _descriptorPool.withResource(() async {
      await file.create(recursive: true);
      await file.writeAsBytes(bytes);
    });
  }

  @override
  Future writeAsString(AssetId id, String contents,
      {Encoding encoding: utf8}) async {
    var file = _fileFor(id, packageGraph);
    await _descriptorPool.withResource(() async {
      await file.create(recursive: true);
      await file.writeAsString(contents, encoding: encoding);
    });
  }

  @override
  Future delete(AssetId id) {
    if (id.package != packageGraph.root.name) {
      throw new InvalidOutputException(
          id, 'Should not delete assets outside of ${packageGraph.root.name}');
    }

    var file = _fileFor(id, packageGraph);
    return _descriptorPool.withResource(() async {
      if (await file.exists()) {
        await file.delete();
      }
    });
  }
}

/// Returns a [File] for [id] given [packageGraph].
File _fileFor(AssetId id, PackageGraph packageGraph) {
  var package = packageGraph[id.package];
  if (package == null) {
    throw new PackageNotFoundException(id.package);
  }
  return new File(path.join(package.path, id.path));
}

/// Returns a [Future<File>] for [id] given [packageGraph].
///
/// Throws an `AssetNotFoundException` if it doesn't exist.
Future<File> _fileForOrThrow(AssetId id, PackageGraph packageGraph) {
  if (packageGraph[id.package] == null) {
    return new Future.error(new PackageNotFoundException(id.package));
  }
  var file = _fileFor(id, packageGraph);
  return _descriptorPool.withResource(file.exists).then((exists) {
    if (!exists) throw new AssetNotFoundException(id);
    return file;
  });
}
