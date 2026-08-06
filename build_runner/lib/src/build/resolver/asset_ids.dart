// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:build/src/asset_id.dart';

extension AssetIdExtension on AssetId {
  /// Returns a new [AssetId] constructed from [package] and [path].
  ///
  /// Normalizes the path; throws on invalid package or path.
  AssetId normalize() => AssetId(package, path);

  bool get isDart => extension == '.dart';

  /// Returns [path] for the current platform.
  String get platformPath => Platform.isWindows ? windowsPath : path;

  /// Returns [path] for Windows.
  ///
  /// Throws an [ArgumentError] if the path contains a colon. This prevents
  /// paths that are relative on POSIX becoming absolute on Windows due to
  /// starting with a drive letter and a colon.
  String get windowsPath {
    if (path.contains(':')) {
      throw ArgumentError.value(
        path,
        'path',
        'Windows paths cannot contain colons.',
      );
    }
    return path.replaceAll('/', '\\');
  }
}
