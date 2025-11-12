// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:build/build.dart';
import 'package:built_collection/built_collection.dart';
import 'package:package_config/package_config.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import '../constants.dart';
import '../io/asset_path_provider.dart';
import '../logging/build_log.dart';

/// The SDK package, we filter this to the core libs and dev compiler
/// resources.
final _sdkPackageNode = PackageNode(
  r'$sdk',
  sdkPath,
  DependencyType.hosted,
  null,
);

/// A graph of the package dependencies for an application.
class PackageGraph implements AssetPathProvider {
  /// The root application package.
  final PackageNode root;

  /// All [PackageNode]s indexed by package name.
  final Map<String, PackageNode> allPackages;

  /// A [PackageConfig] representation of this package graph.
  final PackageConfig asPackageConfig;

  PackageGraph._(this.root, Map<String, PackageNode> allPackages)
    : asPackageConfig = _packagesToConfig(allPackages.values),
      allPackages = Map.unmodifiable(
        Map<String, PackageNode>.from(allPackages)
          ..putIfAbsent(r'$sdk', () => _sdkPackageNode),
      ) {
    if (!root.isRoot) {
      throw ArgumentError('Root node must indicate `isRoot`');
    }
    if (allPackages.values.where((n) => n != root).any((n) => n.isRoot)) {
      throw ArgumentError('No nodes other than the root may indicate `isRoot`');
    }
  }

  /// Creates a [PackageGraph] given the [root] [PackageNode].
  factory PackageGraph.fromRoot(PackageNode root) {
    final allPackages = <String, PackageNode>{root.name: root};

    void addDeps(PackageNode package) {
      for (final dep in package.dependencies) {
        if (allPackages.containsKey(dep.name)) continue;
        allPackages[dep.name] = dep;
        addDeps(dep);
      }
    }

    addDeps(root);

    return PackageGraph._(root, allPackages);
  }

  /// Creates a [PackageGraph] for the package whose top level directory lives
  /// at [packagePath] (no trailing slash).
  static Future<PackageGraph> forPath(String packagePath) async {
    buildLog.debug('forPath $packagePath');

    /// Read in the pubspec file and parse it as yaml.
    final pubspec = File(p.join(packagePath, 'pubspec.yaml'));
    if (!pubspec.existsSync()) {
      throw StateError(
        'Unable to generate package graph, no `pubspec.yaml` found. '
        'This program must be ran from the root directory of your package.',
      );
    }
    final rootPubspec = _pubspecForPath(packagePath);
    final rootPackageName = rootPubspec['name'] as String?;
    if (rootPackageName == null) {
      throw StateError(
        'The current package has no name, please add one to the '
        'pubspec.yaml.',
      );
    }

    // The path of the directory that contains .dart_tool/package_config.json.
    //
    // Should also contain `pubspec.lock`.
    var rootDir = packagePath;
    PackageConfig? packageConfig;
    // Manually recurse through parent directories, to obtain the [rootDir]
    // where a package config was found. It doesn't seem possible to obtain this
    // directly with package:package_config.
    while (true) {
      packageConfig = await findPackageConfig(
        Directory(rootDir),
        recurse: false,
      );
      if (packageConfig != null) {
        break;
      }
      final next = p.dirname(rootDir);
      if (next == rootDir) {
        // We have reached the file system root.
        break;
      }
      rootDir = next;
    }

    if (packageConfig == null) {
      throw StateError(
        'Unable to find package config for package at $packagePath.',
      );
    }
    final dependencyTypes = _parseDependencyTypes(rootDir);

    final nodes = <String, PackageNode>{};
    // A consistent package order _should_ mean a consistent order of build
    // phases. It's not a guarantee, but also not required for correctness, only
    // an optimization.
    final consistentlyOrderedPackages =
        packageConfig.packages.toList()
          ..sort((a, b) => a.name.compareTo(b.name));
    for (final package in consistentlyOrderedPackages) {
      final isRoot = package.name == rootPackageName;
      nodes[package.name] = PackageNode(
        package.name,
        package.root.toFilePath(),
        // If the package is missing from pubspec.lock, assume it is a path
        // dependency.
        dependencyTypes[package.name] ?? DependencyType.path,
        package.languageVersion,
        isRoot: isRoot,
      );
    }
    PackageNode packageNode(String package, {String? parent}) {
      final node = nodes[package];
      if (node == null) {
        throw StateError(
          'Dependency $package ${parent != null ? 'of $parent ' : ''}not '
          'present, please run `dart pub get` or `flutter pub get` to fetch '
          'dependencies.',
        );
      }
      return node;
    }

    final rootNode = packageNode(rootPackageName);
    rootNode.dependencies.addAll(
      _depsFromYaml(
        rootPubspec,
        isRoot: true,
      ).map((n) => packageNode(n, parent: rootPackageName)),
    );

    final packageDependencies = _parsePackageDependencies(
      packageConfig.packages.where((p) => p.name != rootPackageName),
    );
    for (final packageName in packageDependencies.keys) {
      packageNode(packageName).dependencies.addAll(
        packageDependencies[packageName]!.map(
          (n) => packageNode(n, parent: packageName),
        ),
      );
    }
    return PackageGraph._(rootNode, nodes);
  }

  /// Creates a [PackageGraph] for the package in which you are currently
  /// running.
  static Future<PackageGraph> forThisPackage() =>
      PackageGraph.forPath(p.current);

  static PackageConfig _packagesToConfig(Iterable<PackageNode> packages) {
    final relativeLib = Uri.parse('lib/');

    return PackageConfig([
      for (final package in packages)
        if (package.name != _sdkPackageNode.name)
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
  PackageNode? operator [](String packageName) => allPackages[packageName];

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

/// A node in a [PackageGraph].
class PackageNode {
  /// The name of the package as listed in `pubspec.yaml`.
  final String name;

  /// The type of dependency being used to pull in this package.
  ///
  /// May be `null`.
  final DependencyType? dependencyType;

  /// All the packages that this package directly depends on.
  final List<PackageNode> dependencies = [];

  /// The absolute path of the current version of this package.
  ///
  /// Paths are platform dependent.
  final String path;

  /// Whether this node is the [PackageGraph.root].
  final bool isRoot;

  final LanguageVersion? languageVersion;

  PackageNode(
    this.name,
    String path,
    this.dependencyType,
    this.languageVersion, {
    this.isRoot = false,
  }) : path = p.canonicalize(path);

  @override
  String toString() => '''
  $name:
    type: $dependencyType
    path: $path
    dependencies: [${dependencies.map((d) => d.name).join(', ')}]''';
}

/// The type of dependency being used. This dictates how the package should be
/// watched for changes.
enum DependencyType { github, path, hosted }

/// Parse the `pubspec.lock` file and return a Map from package name to the type
/// of dependency.
Map<String, DependencyType> _parseDependencyTypes(String rootPackagePath) {
  final pubspecLock = File(p.join(rootPackagePath, 'pubspec.lock'));
  if (!pubspecLock.existsSync()) {
    throw StateError(
      'Unable to generate package graph, no `pubspec.lock` found. '
      'This program must be ran from the root directory of your package.',
    );
  }
  final dependencyTypes = <String, DependencyType>{};
  final dependencies = loadYaml(pubspecLock.readAsStringSync()) as YamlMap;
  final packages = dependencies['packages'] as YamlMap;
  for (final packageName in packages.keys) {
    final source = (packages[packageName] as YamlMap)['source'];
    dependencyTypes[packageName as String] = _dependencyTypeFromSource(
      source as String,
    );
  }
  return dependencyTypes;
}

DependencyType _dependencyTypeFromSource(String source) {
  switch (source) {
    case 'git':
      return DependencyType.github;
    case 'hosted':
      return DependencyType.hosted;
    case 'path':
    case 'sdk': // Until Flutter supports another type, assum same as path.
      return DependencyType.path;
  }
  throw ArgumentError('Unable to determine dependency type:\n$source');
}

/// Read the pubspec for each package in [packages] and finds it's
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
