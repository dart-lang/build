// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

/// Runs `dart run build_runner build` using `build` packages from pub instead
/// of the local versions. This allows the build to run even when the local
/// versions are in a broken state.
///
/// Usage: in one of the `build` repo packages, instead of running
/// `dart run build_runner build`, run `dart ../tool/build_runner_build.dart`.
void main(List<String> arguments) {
  var repoRoot = Directory.current;
  while (!File.fromUri(
    repoRoot.uri.resolve('.dart_tool/package_config.json'),
  ).existsSync()) {
    final parent = repoRoot.parent;
    if (parent.path == repoRoot.path) {
      print('Current directory should be a package inside the build repo.');
      exit(1);
    }
    repoRoot = parent;
  }

  if (Directory.current.path == repoRoot.path ||
      !File('pubspec.yaml').existsSync()) {
    print('Current directory should be a package inside the build repo.');
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
  build_runner: 2.15.0
  build_test: any
  built_value_generator: any
  json_serializable: any
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
            repoRoot.uri.resolve('.dart_tool/package_config.json'),
          ).readAsStringSync(),
        )
        as Map<String, Object?>,
  );

  // Ensure temp pubConfig and workspace relative URIs are made absolute.
  final tempDotDartToolUri = tempDirectory.uri.resolve('.dart_tool/');
  for (final package in pubConfig.packages) {
    package.rootUri = tempDotDartToolUri.resolve(package.rootUri).toString();
  }

  final workspaceDotDartToolUri = repoRoot.uri.resolve('.dart_tool/');
  for (final package in mergedConfig.packages) {
    package.rootUri = workspaceDotDartToolUri
        .resolve(package.rootUri)
        .toString();
  }

  // Override build packages with published versions from temp pubConfig.
  final currentPackageName = RegExp(
    r'^name:\s*(\S+)',
    multiLine: true,
  ).firstMatch(File('pubspec.yaml').readAsStringSync())?.group(1);

  final buildRunnerPath = pubConfig.packageNamedOrNull('build_runner')!.rootUri;

  for (final package in [
    'build',
    'build_config',
    'build_daemon',
    'build_runner',
    'build_test',
  ]) {
    if (package == currentPackageName) continue;
    final packageConfig = pubConfig.packageNamedOrNull(package);
    if (packageConfig != null) {
      final existing = mergedConfig.packageNamedOrNull(package);
      if (existing != null) {
        existing.rootUri = packageConfig.rootUri;
      } else {
        mergedConfig.addPackage(packageConfig);
      }
    }
  }

  // Add all other packages from pubConfig not present in mergedConfig, such as
  // built_value_generator, json_serializable, and their dependencies.
  for (final package in pubConfig.packages) {
    if (package.name != 'none' &&
        mergedConfig.packageNamedOrNull(package.name) == null) {
      mergedConfig.addPackage(package);
    }
  }

  final repoRootPackageConfigFile = File.fromUri(
    repoRoot.uri.resolve('.dart_tool/package_config.json'),
  );
  final originalPackageConfig = repoRootPackageConfigFile.readAsStringSync();
  final localPubspecFile = File('pubspec.yaml');
  final originalPubspec = localPubspecFile.readAsStringSync();
  var exitCode = 0;
  try {
    repoRootPackageConfigFile.writeAsStringSync(json.encode(mergedConfig));
    localPubspecFile.writeAsStringSync(_injectGenerators(originalPubspec));

    final buildResult = Process.runSync('dart', [
      '--packages=${repoRootPackageConfigFile.path}',
      'run',
      '$buildRunnerPath/bin/build_runner.dart',
      'build',
      '--force-jit',
      ...arguments,
    ], workingDirectory: Directory.current.path);

    stdout.write(buildResult.stdout);
    stderr.write(buildResult.stderr);

    exitCode = buildResult.exitCode;
    if (exitCode == 0) {
      tempDirectory.deleteSync(recursive: true);
    }
  } finally {
    localPubspecFile.writeAsStringSync(originalPubspec);
    repoRootPackageConfigFile.writeAsStringSync(originalPackageConfig);
  }
  exit(exitCode);
}

/// Injects generator dev_dependencies only if not already declared in
/// dependencies or dev_dependencies.
String _injectGenerators(String pubspecContent) {
  final editor = YamlEditor(pubspecContent);
  final doc = loadYaml(pubspecContent);
  if (doc is! Map) return pubspecContent;

  final targetSection = ['dev_dependencies'];
  final devDeps = doc['dev_dependencies'];
  if (devDeps == null) {
    editor.update(targetSection, {});
  }

  final deps = doc['dependencies'] as Map? ?? {};
  final existingDevDeps = doc['dev_dependencies'] as Map? ?? {};

  for (final generator in ['built_value_generator', 'json_serializable']) {
    if (!deps.containsKey(generator) &&
        !existingDevDeps.containsKey(generator)) {
      editor.update([...targetSection, generator], 'any');
    }
  }

  return editor.toString();
}

extension type PackageConfig(Map<String, Object?> node) {
  List<Package> get packages => (node['packages'] as List<Object?>)
      .map((p) => Package(p as Map<String, Object?>))
      .toList();
  Package? packageNamedOrNull(String name) {
    for (final package in packages) {
      if (package.name == name) return package;
    }
    return null;
  }

  void addPackage(Package package) {
    (node['packages'] as List<Object?>).add(package.node);
  }
}

extension type Package(Map<String, Object?> node) {
  String get name => node['name'] as String;
  String get rootUri => node['rootUri'] as String;
  set rootUri(String rootUri) => node['rootUri'] = rootUri;
}
