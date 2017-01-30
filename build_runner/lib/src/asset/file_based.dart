// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:build/build.dart';
import 'package:path/path.dart' as path;

import 'reader.dart';
import 'writer.dart';
import '../generate/input_set.dart';
import '../package_graph/package_graph.dart';

/// Basic [AssetReader] which uses a [PackageGraph] to look up where to read
/// files from disk.
class FileBasedAssetReader implements RunnerAssetReader {
  final PackageGraph packageGraph;
  final List<String> ignoredDirs;

  FileBasedAssetReader(this.packageGraph,
      {this.ignoredDirs: const ['build', 'packages', '.pub']});

  @override
  Future<bool> hasInput(AssetId id) async {
    return _fileFor(id, packageGraph).exists();
  }

  @override
  Future<List<int>> readAsBytes(AssetId id) async =>
      (await _fileForOrThrow(id, packageGraph)).readAsBytes();

  @override
  Future<String> readAsString(AssetId id, {Encoding encoding: UTF8}) async =>
      (await _fileForOrThrow(id, packageGraph))
          .readAsString(encoding: encoding);

  /// Searches for all [AssetId]s matching [inputSet]s.
  @override
  Stream<AssetId> listAssetIds(Iterable<InputSet> inputSets) async* {
    var seenAssets = new Set<AssetId>();
    for (var inputSet in inputSets) {
      var packageNode = packageGraph[inputSet.package];
      if (packageNode == null) {
        throw new ArgumentError(
            "Could not find package '${inputSet.package}' which was listed as "
            "an input. Please ensure you have that package in your deps, or "
            "remove it from your input sets.");
      }
      var packagePath = packageNode.location.toFilePath();
      for (var glob in inputSet.globs) {
        var fileStream = glob.list(followLinks: false, root: packagePath).where(
            (e) => e is File && !ignoredDirs.contains(path.split(e.path)[1]));
        await for (var entity in fileStream) {
          // TODO(jakemac): Where do these files come from???
          if (path.basename(entity.path).startsWith('._')) continue;
          var id = _fileToAssetId(entity, packageNode);
          if (!seenAssets.add(id)) continue;
          yield id;
        }
      }
    }
  }

  @override
  Future<DateTime> lastModified(AssetId id) async =>
      (await _fileForOrThrow(id, packageGraph)).lastModified();
}

/// Creates an [AssetId] for [file], which is a part of [packageNode].
AssetId _fileToAssetId(File file, PackageNode packageNode) {
  var filePath = path.normalize(file.absolute.path);
  var packageUri = packageNode.location;
  var packagePath = path.normalize(packageUri.isAbsolute
      ? packageUri.toFilePath()
      : path.absolute(packageUri.toFilePath()));
  var relativePath = path.relative(filePath, from: packagePath);
  return new AssetId(packageNode.name, relativePath);
}

/// Basic [AssetWriter] which uses a [PackageGraph] to look up where to write
/// files to disk.
class FileBasedAssetWriter implements RunnerAssetWriter {
  final PackageGraph packageGraph;
  @override
  OnDelete onDelete;

  FileBasedAssetWriter(this.packageGraph);

  @override
  Future writeAsBytes(AssetId id, List<int> bytes) async {
    var file = _fileFor(id, packageGraph);
    await file.create(recursive: true);
    await file.writeAsBytes(bytes);
  }

  @override
  Future writeAsString(AssetId id, String contents,
      {Encoding encoding: UTF8}) async {
    var file = _fileFor(id, packageGraph);
    await file.create(recursive: true);
    await file.writeAsString(contents, encoding: encoding);
  }

  @override
  Future delete(AssetId id) {
    assert(id.package == packageGraph.root.name);
    if (onDelete != null) onDelete(id);

    var file = _fileFor(id, packageGraph);
    return () async {
      if (await file.exists()) {
        await file.delete();
      }
    }();
  }
}

/// Returns a [File] for [id] given [packageGraph].
File _fileFor(AssetId id, PackageGraph packageGraph) {
  var package = packageGraph[id.package];
  if (package == null) {
    throw new PackageNotFoundException(id.package);
  }
  return new File(path.join(package.location.toFilePath(), id.path));
}

/// Returns a [Future<File>] for [id] given [packageGraph].
///
/// Throws an `AssetNotFoundException` if it doesn't exist.
Future<File> _fileForOrThrow(AssetId id, packageGraph) async {
  var file = _fileFor(id, packageGraph);
  if (!await file.exists()) throw new AssetNotFoundException(id);
  return file;
}
