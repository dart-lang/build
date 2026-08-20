// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:path/path.dart' as p;

import 'build_file.dart';
import 'build_plan/build_package.dart';
import 'constants.dart';

/// Converts [BuildFile] instances and paths to filesystem paths.
abstract interface class BuildFileLayout {
  /// Converts [file] to a filesystem path.
  ///
  /// Set [checkWriteAllowed] to throw if the file is read only.
  String pathFor(BuildFile file, {bool checkWriteAllowed = false});

  /// Converts a filesystem [path] within [package] to a [BuildFile].
  BuildFile fromPath(BuildPackage package, String path);

  /// Converts a filesystem [path] within [package] to a [BuildFile].
  static BuildFile fileFromPath(BuildPackage package, String path) {
    final relativePath = normalizeRelativePath(package, path);
    final posixPath = p.posix.normalize(relativePath.replaceAll(r'\', '/'));
    final lowerPosixPath = posixPath.toLowerCase();
    if (lowerPosixPath == '.dart_tool' ||
        lowerPosixPath.startsWith('.dart_tool/')) {
      if (posixPath.startsWith('$generatedOutputDirectory/')) {
        final packagePath = posixPath.substring(
          generatedOutputDirectory.length + 1,
        );
        final firstSlash = packagePath.indexOf('/');
        if (firstSlash != -1) {
          final targetPackage = packagePath.substring(0, firstSlash);
          final targetPath = packagePath.substring(firstSlash + 1);
          return AssetFile.cache(AssetId(targetPackage, targetPath));
        }
      }
      return InternalFile(package.name, posixPath);
    }
    return AssetFile.source(AssetId(package.name, posixPath));
  }

  /// Normalizes [path] within [package] to a relative path.
  static String normalizeRelativePath(BuildPackage package, String path) {
    final pkgPath = package.path;
    final absolutePath = p.isAbsolute(path) ? path : p.join(pkgPath, path);
    if (!p.isWithin(pkgPath, absolutePath) && absolutePath != pkgPath) {
      throw ArgumentError('"$absolutePath" is not in "$pkgPath".');
    }
    return p.relative(absolutePath, from: pkgPath);
  }
}
