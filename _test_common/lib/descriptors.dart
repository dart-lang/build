// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';

import 'package:package_config/package_config.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

/// Creates a `pubspec.yaml` file for package [name].
///
/// If [currentIsolateDependencies] is provided then it will add a path
/// dependency for each package listed, assuming it can be resolved in the
/// current isolate.
///
/// If [pathDependencies] is provided then the keys are the package names
/// and the values are the exact paths which will be added as a dependency.
///
/// If [versionDependencies] is provided then the keys are the package names
/// and the values are the exact versions which will be added as a dependency.
Future<d.FileDescriptor> pubspec(String name,
    {Iterable<String> currentIsolateDependencies,
    Map<String, String> pathDependencies,
    Map<String, String> versionDependencies}) async {
  currentIsolateDependencies ??= [];
  pathDependencies ??= {};
  versionDependencies ??= {};

  var buffer = StringBuffer()
    ..writeln('name: $name')
    // Using dependency_overrides forces the path dependency and silences
    // warnings about hosted vs path dependency conflicts.
    ..writeln('dependency_overrides:');

  var packageConfig = await loadPackageConfigUri(await Isolate.packageConfig);
  await Future.forEach(currentIsolateDependencies, (String package) async {
    pathDependencies[package] = packageConfig[package].root.toFilePath();
  });

  pathDependencies.forEach((package, path) {
    buffer..writeln('  $package:')..writeln('    path: $path');
  });

  versionDependencies.forEach((package, version) {
    buffer.writeln('  $package: $version');
  });

  return d.file('pubspec.yaml', buffer.toString());
}
