// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
  final pubConfigLines =
      File.fromUri(
        tempDirectory.uri.resolve('.dart_tool/package_config.json'),
      ).readAsLinesSync();
  var mergedConfig =
      File.fromUri(
        Directory.current.uri.resolve('../.dart_tool/package_config.json'),
      ).readAsStringSync();
  for (final package in [
    'build',
    'build_config',
    'build_daemon',
    'build_resolvers',
    'build_runner',
    'build_runner_core',
    'build_test',
  ]) {
    final pubConfigPattern = RegExp('"rootUri": ".*/$package-.*"');
    final line = pubConfigLines.singleWhere(pubConfigPattern.hasMatch);
    final localConfigPattern = RegExp(
      '^.*"rootUri": "\\.\\./$package"[,]\$',
      multiLine: true,
    );
    mergedConfig = mergedConfig.replaceAll(localConfigPattern, line);
  }
  final mergedConfigFile = File.fromUri(
    tempDirectory.uri.resolve('package_config.json'),
  );
  mergedConfigFile.writeAsStringSync(mergedConfig);

  final buildRunnerPath = pubConfigLines
      .singleWhere((l) => l.contains('/build_runner-2.4.15'))
      .replaceAll('      "rootUri": "', '')
      .replaceAll('",', '');
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
