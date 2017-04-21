import 'dart:io';

import 'package:path/path.dart' as p;

class BazelFileSystem {
  final String workspaceDir;
  final List<String> searchPaths;

  BazelFileSystem(this.workspaceDir, this.searchPaths) {
    if (workspaceDir == null) throw new ArgumentError();
    if (searchPaths == null) throw new ArgumentError();
  }

  //TODO(nbosch) replace with async version
  bool existsSync(String path) {
    for (var searchPath in searchPaths) {
      var f = new File(p.join(workspaceDir, searchPath, path));
      if (f.existsSync()) return true;
    }
    return false;
  }

  //TODO(nbosch) replace with async version
  String readAsStringSync(String path) {
    for (var searchPath in searchPaths) {
      var f = new File(p.join(workspaceDir, searchPath, path));
      if (f.existsSync()) return f.readAsStringSync();
    }
    throw new FileSystemException('File not found', path);
  }
}
