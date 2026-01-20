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

class BuildPackagesLoader {
  /// Loads the build packages for building the package at [packagePath].
  ///
  /// Assumes `pubspec.yaml` exists and has a name, as this is checked by
  /// `dart run`.
  ///
  /// If [workspace], prepares to build the whole workspace, if any.
  static Future<BuildPackages> forPath(
    String packagePath, {
    bool workspace = false,
  }) async {
    String? workspacePath;
    final workspaceRefFile = File(
      p.join(packagePath, '.dart_tool', 'pub', 'workspace_ref.json'),
    );
    File packageConfigFile;
    if (workspaceRefFile.existsSync()) {
      final workspaceRef =
          (json.decode(workspaceRefFile.readAsStringSync())
                  as Map<String, Object?>)['workspaceRoot']
              as String;
      workspacePath = p.canonicalize(
        p.join(p.dirname(workspaceRefFile.path), workspaceRef),
      );
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

    final buildType =
        workspacePath == null
            ? BuildType.singlePackage
            : workspace
            ? BuildType.workspace
            : BuildType.singlePackageInWorkspace;

    final packageConfig = await loadPackageConfig(packageConfigFile);
    final packageConfigs =
        packageConfig.packages.toList()
          ..sort((a, b) => a.name.compareTo(b.name));

    String? workspaceName;
    YamlMap? workspacePubspec;
    if (buildType != BuildType.singlePackage) {
      workspacePubspec = _pubspecForPath(workspacePath!);
      workspaceName = workspacePubspec['name']! as String;
    }

    String? singlePackageToBuild;
    String outputRootName;
    final packagesInBuild = <String>{};
    if (buildType == BuildType.workspace) {
      outputRootName = workspaceName!;
      final workspacePackagePaths = workspacePubspec!['workspace'] as YamlList;
      for (final path in workspacePackagePaths) {
        packagesInBuild.add(
          _pubspecForPath(p.join(workspacePath!, path as String))['name']
              as String,
        );
      }
    } else {
      final singlePackageToBuildPubspec = _pubspecForPath(packagePath);
      singlePackageToBuild = singlePackageToBuildPubspec['name']! as String;
      outputRootName = singlePackageToBuild;
      packagesInBuild.add(singlePackageToBuild);
    }

    // Read the lock file to find "fixed" packages that are hosted, on git
    // or in the SDK and don't have to be watched for file changes.
    final pubspecLockFile = File(
      p.join(workspacePath ?? packagePath, 'pubspec.lock'),
    );
    final fixedPackages = _parseFixedPackages(pubspecLockFile);
    // The workspace root is treated like a package, but does not contain
    // sources so don't watch it for changes.
    // TODO(davidmorgan): add test coverage for yaml files in the workspace
    // root, do watch those for changes.
    if (workspaceName != null) fixedPackages.add(workspaceName);

    final buildPackages = MapBuilder<String, BuildPackage>();
    for (final packageConfig in packageConfigs) {
      final isInBuild = packagesInBuild.contains(packageConfig.name);
      final packagePubspec = _pubspecForPath(packageConfig.root.toFilePath());
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
      singlePackageToBuild: singlePackageToBuild,
      outputRoot: outputRootName,
      packages: buildPackages.build(),
    );
  }
}

enum BuildType {
  /// Single package not in a workspace.
  singlePackage,

  /// Single package in a workspace, but the workspace is ignored.
  singlePackageInWorkspace,

  /// All packages in a workspace.
  workspace,
}

/// Loads and returns `$absolutePath/pubspec.yaml`.
///
/// Throws if it does not exist.
YamlMap _pubspecForPath(String absolutePath) {
  final pubspecPath = p.join(absolutePath, 'pubspec.yaml');
  final pubspec = File(pubspecPath);
  if (!pubspec.existsSync()) {
    throw StateError(
      'Unable to generate package graph, no `$pubspecPath` found.',
    );
  }
  return loadYaml(pubspec.readAsStringSync()) as YamlMap;
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
