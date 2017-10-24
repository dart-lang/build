// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// The parsed values from a Dart `pubspec.yaml` file.
class Pubspec {
  /// Returns a parsed [Pubspec] file in [path], if one exists.
  ///
  /// Otherwise throws [FileSystemException].
  static Future<Pubspec> fromPackageDir(String path) async {
    final pubspec = p.join(path, 'pubspec.yaml');
    final file = new File(pubspec);
    if (await file.exists()) {
      return new Pubspec.parse(await file.readAsString());
    }
    throw new FileSystemException('No file found', p.absolute(pubspec));
  }

  final Map<String, dynamic> _pubspecContents;

  /// Create a [Pubspec] by parsing [pubspecYaml].
  Pubspec.parse(String pubspecYaml)
      : _pubspecContents = loadYaml(pubspecYaml) as Map<String, dynamic>;

  /// Dependencies for a pub package.
  ///
  /// Maps directly to the `dependencies` list in `pubspec.yaml`.
  Iterable<String> get dependencies => _deps('dependencies');

  /// Development dependencies for a pub package.
  ///
  /// Maps directly to the `dev_dependencies` list in `pubspec.yaml`.
  Iterable<String> get devDependencies => _deps('dev_dependencies');

  // Extract dependencies.
  Iterable<String> _deps(String flavor) =>
      (_pubspecContents[flavor] ?? const {}).keys as Iterable<String>;

  /// Name of the package.
  String get pubPackageName => _pubspecContents['name'] as String;
}
