// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:built_collection/built_collection.dart';
import 'package:meta/meta.dart';
import 'package:package_config/package_config.dart';
import 'package:path/path.dart' as p;

/// A Dart package in the build.
class BuildPackage {
  /// The name of the package as listed in `pubspec.yaml`.
  final String name;

  /// The absolute path of the current version of this package.
  ///
  /// Paths are platform dependent.
  final String path;

  /// Whether the "package" is actually a workspace.
  final bool isWorkspace;

  /// Whether the package contents should be watched in `watch` and `serve`
  /// modes.
  final bool watch;

  /// Whether output will be built for this package.
  final bool isOutput;

  final LanguageVersion? languageVersion;

  /// Direct dependencies of the package.
  ///
  /// If [isOutput], includes dev dependencies.
  final BuiltSet<String> dependencies;

  BuildPackage({
    required this.name,
    required String path,
    this.isWorkspace = false,
    this.watch = false,
    this.isOutput = false,
    this.languageVersion,
    Iterable<String> dependencies = const [],
  }) : path = p.canonicalize(path),
       dependencies = dependencies.toBuiltSet();

  /// Creates with a default [path] for testing.
  @visibleForTesting
  factory BuildPackage.forTesting({
    required String name,
    bool isWorkspace = false,
    bool watch = false,
    bool isOutput = false,
    Iterable<String> dependencies = const [],
  }) => BuildPackage(
    name: name,
    path: '/$name',
    isWorkspace: isWorkspace,
    watch: watch,
    isOutput: isOutput,
    dependencies: dependencies,
  );

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is BuildPackage &&
        name == other.name &&
        path == other.path &&
        isWorkspace == other.isWorkspace &&
        watch == other.watch &&
        isOutput == other.isOutput &&
        languageVersion == other.languageVersion &&
        dependencies == other.dependencies;
  }

  @override
  int get hashCode =>
      Object.hash(name, path, watch, isOutput, languageVersion, dependencies);

  @override
  String toString() => '''
BuildPackage(
  name: $name,
  path: $path,
  isWorkspace: $isWorkspace,
  watch: $watch,
  isOutput: $isOutput,
  languageVersion: $languageVersion,
  dependencies: $dependencies,
)''';
}
