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
final _sdkPackage = BuildPackage(r'$sdk', sdkPath, null, isEditable: false);

/// The [BuildPackage]s in the build.
class BuildPackages implements AssetPathProvider {
  /// The package that `build_runner` was launched in.
  ///
  /// TODO(davidmorgan): when running for a workspace there will be no current
  /// package.
  final BuildPackage? current;

  /// The package where output that does not belong to a specific package is
  /// written.
  ///
  /// This includes the `.dart_tool/build` folder with the build script,
  /// compiled build script, generated output and serialized asset graph.
  ///
  /// It is the root for output of performance logs.
  ///
  /// It is also the path where `build_runner` looks for for `build.yaml`
  /// configuration that applies to the whole build instead of to the package
  /// it's in: global options and package-specific overrides.
  ///
  /// TODO(davidmorgan): when workspace support is added this will be a
  /// fake package at the workspace root.
  final BuildPackage outputRoot;

  /// All [BuildPackage]s indexed by package name.
  final Map<String, BuildPackage> allPackages;

  /// A [PackageConfig] representation of this package graph.
  final PackageConfig asPackageConfig;

  /// The names of packages in the build, as distinct from dependency packages
  /// which can be read from but not written to.
  final BuiltSet<String> packagesInBuild;

  BuildPackages._({
    required BuildPackage this.current,
    required this.outputRoot,
    required Map<String, BuildPackage> allPackages,
  }) : asPackageConfig = _packagesToConfig(allPackages.values),
       allPackages = Map.unmodifiable(
         Map<String, BuildPackage>.from(allPackages)
           ..putIfAbsent(r'$sdk', () => _sdkPackage),
       ),
       packagesInBuild = {current.name}.build() {
    if (!current!.isInBuild) {
      throw ArgumentError('Current package must indicate `isInBuild`');
    }
    if (allPackages.values.any((p) => p != current && p.isInBuild)) {
      throw ArgumentError(
        'No packages other than the current may indicate `isInBuild`',
      );
    }
  }

  /// Creates a [BuildPackages] given the [current] [BuildPackage].
  factory BuildPackages.fromCurrent(BuildPackage current) {
    final allPackages = <String, BuildPackage>{current.name: current};

    void addDeps(BuildPackage package) {
      for (final dep in package.dependencies) {
        if (allPackages.containsKey(dep.name)) continue;
        allPackages[dep.name] = dep;
        addDeps(dep);
      }
    }

    addDeps(current);

    return BuildPackages._(
      current: current,
      outputRoot: current,
      allPackages: allPackages,
    );
  }

  /// Loads the package graph for the package at absolute path [packagePath].
  ///
  /// Assumes `pubspec.yaml` exists and has a name, as this is checked by
  /// `dart run`.
  @visibleForTesting
  static Future<BuildPackages> forPath(String packagePath) async {
    var packageConfigFile = File(
      p.join(packagePath, '.dart_tool', 'package_config.json'),
    );
    String? workspacePath;
    if (!packageConfigFile.existsSync()) {
      final workspaceRefFile = File(
        p.join(packagePath, '.dart_tool', 'pub', 'workspace_ref.json'),
      );
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
      }
    }

    if (!packageConfigFile.existsSync()) {
      throw StateError('Failed to find package_config.json.');
    }

    final packageConfig = await loadPackageConfig(packageConfigFile);

    final buildPackages = <String, BuildPackage>{};
    final packageConfigs =
        packageConfig.packages.toList()
          ..sort((a, b) => a.name.compareTo(b.name));

    final currentPubspec = _pubspecForPath(packagePath);
    final currentPackageName = currentPubspec['name']! as String;
    final pubspecLockFile = File(
      p.join(workspacePath ?? packagePath, 'pubspec.lock'),
    );
    final fixedPackages = _parseFixedPackages(pubspecLockFile);

    for (final packageConfig in packageConfigs) {
      final isRoot = packageConfig.name == currentPackageName;
      buildPackages[packageConfig.name] = BuildPackage(
        packageConfig.name,
        packageConfig.root.toFilePath(),
        packageConfig.languageVersion,
        isEditable: !fixedPackages.contains(packageConfig.name),
        isInBuild: isRoot,
      );
    }

    BuildPackage createPackage(String packageName, {String? parent}) {
      final buildPackage = buildPackages[packageName];
      if (buildPackage == null) {
        throw StateError(
          'Dependency $packageName ${parent != null ? 'of $parent ' : ''}not '
          'present, please run `dart pub get` or `flutter pub get` to fetch '
          'dependencies.',
        );
      }
      return buildPackage;
    }

    final currentPackage = createPackage(currentPackageName);
    currentPackage.dependencies.addAll(
      _depsFromYaml(
        currentPubspec,
        isRoot: true,
      ).map((n) => createPackage(n, parent: currentPackageName)),
    );

    final packageDependencies = _parsePackageDependencies(
      packageConfig.packages.where((p) => p.name != currentPackageName),
    );
    for (final packageName in packageDependencies.keys) {
      createPackage(packageName).dependencies.addAll(
        packageDependencies[packageName]!.map(
          (n) => createPackage(n, parent: packageName),
        ),
      );
    }

    // A workspace can have packages that are not depended on by [rootPackage].
    // Compute transitive dependencies and filter to that.
    Set<BuildPackage>? usedPackages;
    if (workspacePath != null) {
      usedPackages = {currentPackage};
      final queue = [currentPackage];
      while (queue.isNotEmpty) {
        final package = queue.removeLast();
        for (final dep in package.dependencies) {
          if (usedPackages.add(dep)) {
            queue.add(dep);
          }
        }
      }
    }

    return BuildPackages._(
      current: currentPackage,
      outputRoot: currentPackage,
      allPackages:
          usedPackages == null
              ? buildPackages
              : Map.fromEntries(
                buildPackages.entries.where(
                  (e) => usedPackages!.contains(e.value),
                ),
              ),
    );
  }

  /// Creates a [BuildPackages] for the package in which you are currently
  /// running.
  static Future<BuildPackages> forThisPackage() =>
      BuildPackages.forPath(p.current);

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
      // Delete is allowed if it's a hidden output or if it's an output to a
      // package in the build. This forbids deleting files that are part of the
      // checked-in source tree of a dependency package.
      if (!(hide || packagesInBuild.contains(id.package))) {
        throw InvalidOutputException(
          id,
          'Should not delete assets outside of package(s): '
          '${packagesInBuild.join(', ')}',
        );
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

/// Read the pubspec for each package in [packages] and finds its
/// dependencies.
Map<String, List<String>> _parsePackageDependencies(
  Iterable<Package> packages,
) {
  final dependencies = <String, List<String>>{};
  for (final package in packages) {
    final pubspec = _pubspecForPath(package.root.toFilePath());
    dependencies[package.name] = _depsFromYaml(pubspec);
  }
  return dependencies;
}

/// Gets the deps from a yaml file, omitting dependency_overrides.
List<String> _depsFromYaml(YamlMap yaml, {bool isRoot = false}) {
  final deps = <String>{
    ..._stringKeys(yaml['dependencies'] as Map?),
    if (isRoot) ..._stringKeys(yaml['dev_dependencies'] as Map?),
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
