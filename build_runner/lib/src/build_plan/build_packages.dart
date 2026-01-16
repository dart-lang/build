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
  /// The root application package.
  final BuildPackage root;

  /// All [BuildPackage]s indexed by package name.
  final Map<String, BuildPackage> allPackages;

  /// A [PackageConfig] representation of this package graph.
  final PackageConfig asPackageConfig;

  BuildPackages._(this.root, Map<String, BuildPackage> allPackages)
    : asPackageConfig = _packagesToConfig(allPackages.values),
      allPackages = Map.unmodifiable(
        Map<String, BuildPackage>.from(allPackages)
          ..putIfAbsent(r'$sdk', () => _sdkPackage),
      ) {
    if (!root.isRoot) {
      throw ArgumentError('Root package must indicate `isRoot`');
    }
    if (allPackages.values.where((n) => n != root).any((n) => n.isRoot)) {
      throw ArgumentError(
        'No packages other than the root may indicate `isRoot`',
      );
    }
  }

  /// Creates a [BuildPackages] given the [root] [BuildPackage].
  factory BuildPackages.fromRoot(BuildPackage root) {
    final allPackages = <String, BuildPackage>{root.name: root};

    void addDeps(BuildPackage package) {
      for (final dep in package.dependencies) {
        if (allPackages.containsKey(dep.name)) continue;
        allPackages[dep.name] = dep;
        addDeps(dep);
      }
    }

    addDeps(root);

    return BuildPackages._(root, allPackages);
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
    final packageNames =
        packageConfig.packages.toList()
          ..sort((a, b) => a.name.compareTo(b.name));

    final rootPubspec = _pubspecForPath(packagePath);
    final rootPackageName = rootPubspec['name']! as String;
    final pubspecLockFile = File(
      p.join(workspacePath ?? packagePath, 'pubspec.lock'),
    );
    final fixedPackages = _parseFixedPackages(pubspecLockFile);

    for (final package in packageNames) {
      final isRoot = package.name == rootPackageName;
      buildPackages[package.name] = BuildPackage(
        package.name,
        package.root.toFilePath(),
        package.languageVersion,
        isEditable: !fixedPackages.contains(package.name),
        isRoot: isRoot,
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

    final rootPackage = createPackage(rootPackageName);
    rootPackage.dependencies.addAll(
      _depsFromYaml(
        rootPubspec,
        isRoot: true,
      ).map((n) => createPackage(n, parent: rootPackageName)),
    );

    final packageDependencies = _parsePackageDependencies(
      packageConfig.packages.where((p) => p.name != rootPackageName),
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
      usedPackages = {rootPackage};
      final queue = [rootPackage];
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
      rootPackage,
      usedPackages == null
          ? buildPackages
          : Map.fromEntries(
            buildPackages.entries.where((e) => usedPackages!.contains(e.value)),
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
  String pathFor(AssetId id) {
    final package = this[id.package];
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
