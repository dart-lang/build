// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

/// Runs `dart run build_runner build` using `build` packages from pub instead
/// of the local versions. This allows the build to run even when the local
/// versions are in a broken state.
///
/// Usage: in one of the `build` repo packages, instead of running
/// `dart run build_runner build`, run `dart ../tool/build_runner_build.dart`.
void main() {
  final pathSegments = Directory.current.uri.pathSegments;
  if (pathSegments[pathSegments.length - 3] != 'build') {
    print('Current directly should be a package inside the build repo.');
    exit(1);
  }

  // Run `pub get` in a temp folder to get paths for published versions of
  // `build` packages that won't break due to local changes.
  final tempDirectory = Directory.systemTemp.createTempSync(
    'build_runner_build',
  );
  tempDirectory.createSync(recursive: true);
  File.fromUri(tempDirectory.uri.resolve('pubspec.yaml')).writeAsStringSync('''
name: none
environment:
  sdk: ^3.7.0
dependencies:
  build_runner: '2.4.15'
  build_test: any
''');
  Process.runSync('dart', ['pub', 'get'], workingDirectory: tempDirectory.path);
  final pubConfig = PackageConfig(
    json.decode(
          File.fromUri(
            tempDirectory.uri.resolve('.dart_tool/package_config.json'),
          ).readAsStringSync(),
        )
        as Map<String, Object?>,
  );

  // Merge `pubConfig` into the local package config.
  //
  // `build_runner` expects to run with the local package config because it
  // creates a build script that depends on whatever generators the local
  // package uses.
  //
  // So the merged config will have the two things needed: `build` packages
  // not broken by local changes, and whatever generators are needed.
  var mergedConfig = PackageConfig(
    json.decode(
          File.fromUri(
            Directory.current.uri.resolve('../.dart_tool/package_config.json'),
          ).readAsStringSync(),
        )
        as Map<String, Object?>,
  );

  late String buildRunnerPath;
  for (final package in [
    'build',
    'build_config',
    'build_daemon',
    'build_resolvers',
    'build_runner',
    'build_runner_core',
    'build_test',
  ]) {
    final packageConfig = pubConfig.packageNamed(package);
    mergedConfig.packageNamed(package).rootUri = packageConfig.rootUri;
    if (package == 'build_runner') {
      buildRunnerPath = packageConfig.rootUri;
    }
  }
  final mergedConfigFile = File.fromUri(
    tempDirectory.uri.resolve('package_config.json'),
  );
  mergedConfigFile.writeAsStringSync(json.encode(mergedConfig));

  final buildResult = Process.runSync('dart', [
    '--packages=${mergedConfigFile.path}',
    'run',
    '$buildRunnerPath/bin/build_runner.dart',
    'build',
    '-d',
  ], workingDirectory: Directory.current.path);

  stdout.write(buildResult.stdout);
  stderr.write(buildResult.stderr);

  if (buildResult.exitCode == 0) {
    tempDirectory.deleteSync(recursive: true);
  }
  exit(buildResult.exitCode);
}

extension type PackageConfig(Map<String, Object?> node) {
  List<Package> get packages =>
      (node['packages'] as List<Object?>)
          .map((p) => Package(p as Map<String, Object?>))
          .toList();
  Package packageNamed(String name) =>
      packages.singleWhere((package) => package.name == name);
}

extension type Package(Map<String, Object?> node) {
  String get name => node['name'] as String;
  String get rootUri => node['rootUri'] as String;
  set rootUri(String rootUri) => node['rootUri'] = rootUri;
}
