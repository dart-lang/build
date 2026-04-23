// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:built_collection/built_collection.dart';
import 'package:package_config/package_config.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import 'build_package.dart';
import 'build_packages.dart';
import 'build_paths.dart';
import 'pubspecs.dart';

class BuildPackagesLoader {
  /// Loads the build packages for building [paths].
  ///
  /// Assumes `pubspec.yaml` exists and has a name, as this is checked by
  /// `dart run`.
  static Future<BuildPackages> forPaths(BuildPaths paths) async {
    final packagePath = paths.packagePath;
    final workspacePath = paths.workspacePath;
    File packageConfigFile;
    if (workspacePath != null) {
      packageConfigFile = File(
        p.join(workspacePath, '.dart_tool', 'package_config.json'),
      );
    } else {
      packageConfigFile = File(
        p.join(packagePath, '.dart_tool', 'package_config.json'),
      );
    }
    if (!packageConfigFile.existsSync()) {
      throw StateError('Failed to find package_config.json.');
    }

    final buildType = paths.buildType;

    final packageConfig = await loadPackageConfig(packageConfigFile);
    final packageConfigs =
        packageConfig.packages.toList()
          ..sort((a, b) => a.name.compareTo(b.name));

    String? workspaceName;
    List<String>? workspacePackages;
    if (buildType != BuildType.singlePackage) {
      final workspacePubspec = Pubspecs.load(
        p.join(workspacePath!, 'pubspec.yaml'),
      );
      workspaceName = workspacePubspec['name']! as String;
      final workspacePackageGraph = _packageGraphForPath(workspacePath);
      workspacePackages = List.from(
        workspacePackageGraph['roots'] as List<Object?>,
      );
    }

    final currentPackagePubspec = Pubspecs.load(
      p.join(packagePath, 'pubspec.yaml'),
    );
    final currentPackage = currentPackagePubspec['name']! as String;

    String? singlePackageToBuild;
    String outputRootName;
    final packagesInBuild = <String>{};
    if (buildType == BuildType.workspace) {
      packagesInBuild.add(workspaceName!);
      packagesInBuild.addAll(workspacePackages!);
      outputRootName = workspaceName;
    } else {
      singlePackageToBuild = currentPackage;
      outputRootName = currentPackage;
      packagesInBuild.add(currentPackage);
    }

    // Read the lock file to find "fixed" packages that are hosted, on git
    // or in the SDK and don't have to be watched for file changes.
    final pubspecLockFile = File(
      p.join(workspacePath ?? packagePath, 'pubspec.lock'),
    );
    final fixedPackages = _parseFixedPackages(pubspecLockFile);

    final buildPackages = MapBuilder<String, BuildPackage>();
    for (final packageConfig in packageConfigs) {
      final isInBuild = packagesInBuild.contains(packageConfig.name);
      final packagePubspec = Pubspecs.load(
        p.join(packageConfig.root.toFilePath(), 'pubspec.yaml'),
      );
      final dependencies = _depsFromYaml(
        packagePubspec,
        loadDevDependencies: isInBuild,
      );
      buildPackages[packageConfig.name] = BuildPackage(
        name: packageConfig.name,
        path: packageConfig.root.toFilePath(),
        languageVersion: packageConfig.languageVersion,
        watch: !fixedPackages.contains(packageConfig.name),
        isOutput: isInBuild,
        dependencies: dependencies,
      );
    }

    return BuildPackages.compute(
      currentPackage: currentPackage,
      singlePackageToBuild: singlePackageToBuild,
      outputRoot: outputRootName,
      packages: buildPackages.build(),
    );
  }
}

/// Loads and returns `$absolutePath/pubspec.yaml`.
///
/// Throws if it does not exist.

/// Loads and returns `$absolutePath/.dart_tool/package_graph.json`.
///
/// Throws if it does not exist.
Map<String, Object?> _packageGraphForPath(String absolutePath) {
  final packageGraphPath = p.join(
    absolutePath,
    '.dart_tool',
    'package_graph.json',
  );
  final packageGraph = File(packageGraphPath);
  if (!packageGraph.existsSync()) {
    throw StateError('Unable to load packages, no `$packageGraphPath` found.');
  }
  return json.decode(packageGraph.readAsStringSync()) as Map<String, Object?>;
}

/// Parses the `pubspec.lock` file and returns the names of packages that are
/// "fixed": hosted, on git or in the SDK.
Set<String> _parseFixedPackages(File pubspecLockFile) {
  final result = <String>{};
  final dependencies = loadYaml(pubspecLockFile.readAsStringSync()) as YamlMap;
  final packages = dependencies['packages'] as YamlMap;
  for (final packageName in packages.keys) {
    final source = (packages[packageName] as YamlMap)['source'] as String?;
    if (source == 'git' || source == 'hosted' || source == 'sdk') {
      result.add(packageName as String);
    }
  }
  return result;
}

/// Gets the deps from a yaml file, omitting dependency_overrides.
///
/// If [loadDevDependencies] loads the dev_dependencies as well as the main
/// dependencies.
List<String> _depsFromYaml(YamlMap yaml, {bool loadDevDependencies = false}) {
  final result = <String>{
    ..._stringKeys(yaml['dependencies'] as Map?),
    if (loadDevDependencies) ..._stringKeys(yaml['dev_dependencies'] as Map?),
  };
  // Sort the result to make builds more stable.
  return result.toList()..sort();
}

Iterable<String> _stringKeys(Map? m) =>
    m == null ? const [] : m.keys.cast<String>();
