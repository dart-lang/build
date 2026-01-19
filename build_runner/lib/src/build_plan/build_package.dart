// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:package_config/package_config.dart';
import 'package:path/path.dart' as p;

/// A Dart package in the build.
class BuildPackage {
  /// The name of the package as listed in `pubspec.yaml`.
  final String name;

  /// Whether the package is editable.
  ///
  /// It's editable if it's a path dependency or in the current workspace; it's
  /// not editable if it's a hosted or git dependency.
  final bool isEditable;

  /// All the packages that this package directly depends on.
  final List<BuildPackage> dependencies = [];

  /// The absolute path of the current version of this package.
  ///
  /// Paths are platform dependent.
  final String path;

  /// Whether output will be built for this package.
  final bool isInBuild;

  final LanguageVersion? languageVersion;

  BuildPackage(
    this.name,
    String path,
    this.languageVersion, {
    required this.isEditable,
    this.isInBuild = false,
  }) : path = p.canonicalize(path);

  @override
  String toString() => '''
  $name:
    isEditable: $isEditable
    isInBuild: $isInBuild
    path: $path
    dependencies: [${dependencies.map((d) => d.name).join(', ')}]''';
}
