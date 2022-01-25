// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

const _buildPackages = [
  'build',
  'build_config',
  'build_daemon',
  'build_modules',
  'build_resolvers',
  'build_runner',
  'build_runner_core',
  'build_test',
  'build_vm_compilers',
  'build_web_compilers',
  'scratch_space',
];

/// Adds `dependency_overrides` for to a pubspec.yaml file in [packageDir]
/// build packages, assuming that the current working directory is the root of
/// the `build` repository checkout.
Future<void> patchBuildDependencies(String packageDir) async {
  final pubspec = File(p.join(packageDir, 'pubspec.yaml'));

  if (!await pubspec.exists()) {
    throw UnsupportedError('No pubspec.yaml in $packageDir');
  }

  final editor = YamlEditor(await pubspec.readAsString());

  const targetSection = ['dependency_overrides'];
  if (editor
          .parseAt(targetSection, orElse: () => YamlScalar.wrap(null))
          .value ==
      null) {
    // There are no `dependency_overrides` in this pubspec, so create an empty
    // block first.
    editor.update(targetSection, {});
  }

  final buildCheckout = Directory.current.path;

  for (final buildPackage in _buildPackages) {
    final path = p.join(buildCheckout, buildPackage);
    editor.update([...targetSection, buildPackage], {'path': path});
  }

  await pubspec.writeAsString(editor.toString());
}
