library source_gen.io;

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;

/// Skips symbolic links and any item in [directryPath] recursively that begins
/// with `.`.
Stream<String> getFiles(String directoryPath) {
  var controller = new StreamController<String>();

  var rootDir = new Directory(directoryPath);

  _populateFiles(rootDir, controller).catchError((error, stack) {
    controller.addError(error, stack);
  }).whenComplete(() {
    controller.close();
  });

  return controller.stream;
}

Future _populateFiles(Directory dir, StreamController<String> controller) {
  return dir.list(recursive: false, followLinks: false).asyncMap((fse) {
    if (p.basename(fse.path).startsWith('.')) {
      return null;
    }

    if (fse is File) {
      controller.add(fse.path);
    } else if (fse is Directory) {
      return _populateFiles(fse, controller);
    }
  }).drain();
}
