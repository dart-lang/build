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
void main(List<String> arguments) {
  final pathSegments = Directory.current.uri.pathSegments;
  if (pathSegments[pathSegments.length - 2] != 'build_runner') {
    print('Current directory should be a package inside the build repo.');
    exit(1);
  }

  String? buildRunnerOverride;
  if (arguments.length == 1) {
    buildRunnerOverride = arguments[0];
  } else if (arguments.length > 1) {
    print(
      'Usage: build_runner_build.dart [optional build_runner package path]',
    );
  }

  // Run `pub get` in a temp folder to get paths for published versions of
  // `build` packages that won't break due to local changes.
  final tempDirectory = Directory.systemTemp.createTempSync(
    'build_runner_build',
  );
  tempDirectory.createSync(recursive: true);
  final maybeOverride = buildRunnerOverride == null
      ? ''
      : '''
dependency_overrides:
  build_runner:
    path: $buildRunnerOverride
''';
  File.fromUri(tempDirectory.uri.resolve('pubspec.yaml')).writeAsStringSync('''
name: none
environment:
  sdk: ^3.7.0
dependencies:
  build_runner: 2.15.0
  build_test: any
$maybeOverride
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
  final mergedConfig = PackageConfig(
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
    'build_runner',
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
    '--force-jit',
  ], workingDirectory: Directory.current.path);

  stdout.write(buildResult.stdout);
  stderr.write(buildResult.stderr);

  if (buildResult.exitCode == 0) {
    tempDirectory.deleteSync(recursive: true);
  }
  exit(buildResult.exitCode);
}

extension type PackageConfig(Map<String, Object?> node) {
  List<Package> get packages => (node['packages'] as List<Object?>)
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
