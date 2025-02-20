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
///
/// The [sdkEnvironment] describes the `environment.sdk` field in the pubspec.
Future<d.FileDescriptor> pubspec(
  String name, {
  Iterable<String> currentIsolateDependencies = const [],
  Map<String, String> pathDependencies = const {},
  Map<String, String> versionDependencies = const {},
  String sdkEnvironment = '>=2.12.0 <4.0.0',
}) async {
  var buffer =
      StringBuffer()
        ..writeln('name: $name')
        ..writeln('environment:')
        ..writeln('  sdk: "$sdkEnvironment"')
        ..writeln('dependencies:');

  // Add all deps as `any` deps, real versions are set in dependency_overrides
  // below.
  var allPackages = [
    ...currentIsolateDependencies,
    ...pathDependencies.keys,
    ...versionDependencies.keys,
  ];
  for (var package in allPackages) {
    buffer.writeln('  $package: any');
  }

  // Using dependency_overrides forces the path dependency and silences
  // warnings about hosted vs path dependency conflicts.
  buffer.writeln('dependency_overrides:');

  var packageConfig = await loadPackageConfigUri(
    (await Isolate.packageConfig)!,
  );

  void addPathDep(String package, String path) {
    buffer
      ..writeln('  $package:')
      ..writeln('    path: $path');
  }

  await Future.forEach(currentIsolateDependencies, (String package) async {
    addPathDep(package, packageConfig[package]!.root.toFilePath());
  });

  pathDependencies.forEach(addPathDep);

  versionDependencies.forEach((package, version) {
    buffer.writeln('  $package: $version');
  });

  return d.file('pubspec.yaml', buffer.toString());
}
