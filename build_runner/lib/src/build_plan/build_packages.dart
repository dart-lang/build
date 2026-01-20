// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:build/build.dart';
import 'package:built_collection/built_collection.dart';
import 'package:meta/meta.dart';
import 'package:package_config/package_config.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import '../constants.dart';
import '../io/asset_path_provider.dart';
import 'build_package.dart';

/// The SDK package, we filter this to the core libs and dev compiler
/// resources.
final _sdkPackage = BuildPackage(name: r'$sdk', path: sdkPath);

/// The [BuildPackage]s in the build.
class BuildPackages implements AssetPathProvider {
  /// When building a single package, the package to build, which is also the
  /// package `build_runner` was launched in.
  ///
  /// When building a workspace, `null`.
  final BuildPackage? singlePackageToBuild;

  /// The package where output that does not belong to a specific package is
  /// written.
  ///
  /// When building a workspace, the workspace root.
  ///
  /// Output includes the `.dart_tool/build` folder with the build script,
  /// compiled build script, generated output and serialized asset graph.
  ///
  /// Also the root for output of performance logs.
  ///
  /// Also the path where `build_runner` looks for for `build.yaml`
  /// configuration that applies to the whole build instead of to the package
  /// it's in: global options and package-specific overrides.
  ///
  final BuildPackage outputRoot;

  /// All [BuildPackage]s indexed by package name.
  final Map<String, BuildPackage> allPackages;

  /// A [PackageConfig] representation of this package graph.
  final PackageConfig asPackageConfig;

  /// The names of packages in the build, as distinct from dependency packages
  /// which can be read from but not written to.
  final BuiltSet<String> packagesInBuild;

  /// For each package, the packages from which to auto apply builders.
  ///
  /// For example, `builderPackagesToAutoApplyByPackage['a']` is the set of
  /// packages that can have builders that auto apply to `a`.
  final BuiltSetMultimap<String, String> builderPackagesToAutoApplyByPackage;

  BuildPackages._({
    required this.singlePackageToBuild,
    required this.outputRoot,
    required Map<String, BuildPackage> allPackages,
  }) : asPackageConfig = _packagesToConfig(allPackages.values),
       allPackages = Map.unmodifiable(
         Map<String, BuildPackage>.from(allPackages)
           ..putIfAbsent(r'$sdk', () => _sdkPackage),
       ),
       packagesInBuild =
           allPackages.values
               .where((b) => b.isInBuild)
               .map((p) => p.name)
               .toBuiltSet(),
       builderPackagesToAutoApplyByPackage =
           _builderPackagesToAutoApplyByPackage(allPackages);

  /// Creates [BuildPackages] from [BuildPackage]s for building
  /// [singlePackageToBuild].
  @visibleForTesting
  factory BuildPackages.fromPackages(
    Iterable<BuildPackage> packages, {
    required String singlePackageToBuild,
  }) {
    final allPackages = {for (final package in packages) package.name: package};
    return BuildPackages._(
      singlePackageToBuild: allPackages[singlePackageToBuild]!,
      outputRoot: allPackages[singlePackageToBuild]!,
      allPackages: allPackages,
    );
  }

  /// Loads the build packages for building the package at [packagePath].
  ///
  /// Assumes `pubspec.yaml` exists and has a name, as this is checked by
  /// `dart run`.
  ///
  /// If [workspace], prepares to build the whole workspace, if any.
  @visibleForTesting
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
            ? _BuildType.singlePackage
            : workspace
            ? _BuildType.workspace
            : _BuildType.singlePackageInWorkspace;

    final packageConfig = await loadPackageConfig(packageConfigFile);
    final packageConfigs =
        packageConfig.packages.toList()
          ..sort((a, b) => a.name.compareTo(b.name));

    String? workspaceName;
    YamlMap? workspacePubspec;
    if (buildType != _BuildType.singlePackage) {
      workspacePubspec = _pubspecForPath(workspacePath!);
      workspaceName = workspacePubspec['name']! as String;
    }

    String? singlePackageToBuild;
    String outputRootName;
    final packagesInBuild = <String>{};
    if (buildType == _BuildType.workspace) {
      outputRootName = workspaceName!;
      final workspacePackagePaths = workspacePubspec!['workspace'] as YamlList;
      for (final path in workspacePackagePaths) {
        packagesInBuild.add(
          _pubspecForPath(p.join(workspacePath!, path as String))['name']
              as String,
        );
      }
    } else {
      final currentPubspec = _pubspecForPath(packagePath);
      singlePackageToBuild = currentPubspec['name']! as String;
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

    final buildPackages = <String, BuildPackage>{};
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
        isInBuild: isInBuild,
        dependencies: dependencies,
      );
    }
    for (final package in buildPackages.values) {
      for (final dependency in package.dependencies) {
        if (!buildPackages.containsKey(dependency)) {
          throw StateError(
            'Dependency $dependency of $package not present, please run '
            '`dart pub get` or `flutter pub get` to fetch dependencies.',
          );
        }
      }
    }

    // If building in a workspace but not building the whole workspace, filter
    // to packages that are a dependency of `singlePackageToBuild`.
    if (buildType == _BuildType.singlePackageInWorkspace) {
      final transitiveDeps = _transitiveDepsOf(
        packages: [singlePackageToBuild!],
        allPackages: buildPackages,
      );
      buildPackages.removeWhere((name, _) => !transitiveDeps.contains(name));
    }

    return BuildPackages._(
      singlePackageToBuild: buildPackages[singlePackageToBuild],
      outputRoot: buildPackages[outputRootName]!,
      allPackages: buildPackages,
    );
  }

  /// Creates a [BuildPackages] for the package in which you are currently
  /// running.
  ///
  /// If [workspace], prepares to build for the whole workspace, if any.
  static Future<BuildPackages> forThisPackage({bool workspace = false}) =>
      BuildPackages.forPath(p.current, workspace: workspace);

  static PackageConfig _packagesToConfig(Iterable<BuildPackage> packages) {
    final relativeLib = Uri.parse('lib/');

    return PackageConfig([
      for (final package in packages)
        if (package.name != _sdkPackage.name)
          Package(
            package.name,
            Uri.file(
              package.path.endsWith('/') ? package.path : '${package.path}/',
            ),
            languageVersion: package.languageVersion,
            packageUriRoot: relativeLib,
          ),
    ]);
  }

  /// Shorthand to get a package by name.
  BuildPackage? operator [](String packageName) => allPackages[packageName];

  /// Map from package name to package language version.
  BuiltMap<String, LanguageVersion?> get languageVersions =>
      {
        for (final package in allPackages.values)
          package.name: package.languageVersion,
      }.build();

  @override
  String pathFor(
    AssetId id, {
    required bool hide,
    bool checkDeleteAllowed = false,
  }) {
    if (checkDeleteAllowed) {
      // Delete is allowed if it's a hidden output in `outputRoot` or if it's a
      // package in the build.
      final isUnderCacheDirectory = id.path.startsWith('$cacheDirectoryPath/');
      final deleteIsAllowed =
          hide ||
          (isUnderCacheDirectory && id.package == outputRoot.name) ||
          packagesInBuild.contains(id.package);
      if (!deleteIsAllowed) {
        if (isUnderCacheDirectory) {
          throw InvalidOutputException(
            id,
            'Tried to delete from $cacheDirectoryPath in wrong package, should '
            'be ${outputRoot.name}.',
          );
        } else {
          throw InvalidOutputException(
            id,
            'Tried to delete from package not in the build. Packages in the '
            'build are: ${packagesInBuild.join(', ')}',
          );
        }
      }
    }

    if (hide) {
      id = AssetPathProvider.hide(id, outputRoot.name);
    }
    final package = allPackages[id.package];
    if (package == null) {
      throw PackageNotFoundException(id.package);
    }
    var path = id.path;
    if (Platform.pathSeparator != '/') {
      path = path.replaceAll('/', Platform.pathSeparator);
    }
    return p.join(package.path, path);
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    for (final package in allPackages.values) {
      buffer.writeln('$package');
    }
    return buffer.toString();
  }
}

/// Parse the `pubspec.lock` file and return the names of packages that are
/// hosted, on git or in the SDK.
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
  final deps = <String>{
    ..._stringKeys(yaml['dependencies'] as Map?),
    if (loadDevDependencies) ..._stringKeys(yaml['dev_dependencies'] as Map?),
  };
  // A consistent package order _should_ mean a consistent order of build
  // phases. It's not a guarantee, but also not required for correctness, only
  // an optimization.
  return deps.toList()..sort();
}

Iterable<String> _stringKeys(Map? m) =>
    m == null ? const [] : m.keys.cast<String>();

/// Should point to the top level directory for the package.
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

enum _BuildType {
  /// Single package not in a workspace.
  singlePackage,

  /// Single package in a workspace, but the workspace is ignored.
  singlePackageInWorkspace,

  /// All packages in a workspace.
  workspace,
}

/// Returns a map of packages that can apply builders to each package.
///
/// To calculate this set for each package: first, find all reverse deps of the
/// package that have `isInBuild` set. These are the "build packages" that can
/// introduce builders.
///
/// Then, the result is the union the set of build packages and all their direct
/// deps.
BuiltSetMultimap<String, String> _builderPackagesToAutoApplyByPackage(
  Map<String, BuildPackage> allPackages,
) {
  final result = SetMultimapBuilder<String, String>();

  for (final package in allPackages.values) {
    if (!package.isInBuild) continue;

    final transitiveDeps = _transitiveDepsOf(
      packages: [package.name],
      allPackages: allPackages,
    );

    for (final dependency in transitiveDeps) {
      result.add(dependency, package.name);
      result.addValues(dependency, package.dependencies);
    }
  }

  return result.build();
}

/// Returns all transitive deps of [packages] according to the deps in
/// [allPackages].
Set<String> _transitiveDepsOf({
  required Iterable<String> packages,
  required Map<String, BuildPackage> allPackages,
}) {
  final result = packages.toSet();
  final queue = packages.toList();
  while (queue.isNotEmpty) {
    final package = queue.removeLast();
    for (final dependency in allPackages[package]!.dependencies) {
      if (result.add(dependency)) {
        queue.add(dependency);
      }
    }
  }
  return result;
}
