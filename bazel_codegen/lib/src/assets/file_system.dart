// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:glob/glob.dart';

/// A filesystem that can search for paths under multiple roots.
class BazelFileSystem {
  final String workspaceDir;
  final List<String> searchPaths;

  BazelFileSystem(this.workspaceDir, this.searchPaths) {
    if (workspaceDir == null) throw new ArgumentError();
    if (searchPaths == null) throw new ArgumentError();
  }

  Future<bool> exists(String path) async => (await _fileForPath(path)) != null;

  Future<File> find(String path) async {
    var file = await _fileForPath(path);
    if (file == null) throw new FileSystemException('File not found', path);
    return file;
  }

  Iterable<String> findAssets(String packagePath, Glob glob) sync* {
    for (var searchPath in searchPaths) {
      var fullPath = p.join(workspaceDir, searchPath, packagePath);
      if (!new Directory(fullPath).existsSync()) continue;
      yield* glob
          .listSync(root: fullPath)
          .map((e) => e.path)
          .map((path) => p.relative(path, from: fullPath));
    }
  }

  Future<File> _fileForPath(String path) async {
    for (var searchPath in searchPaths) {
      var f = new File(p.join(workspaceDir, searchPath, path));
      if (await f.exists()) return f;
    }
    return null;
  }
}
