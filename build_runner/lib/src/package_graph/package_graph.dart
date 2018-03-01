// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:cli_util/cli_util.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// The SDK package, we filter this to the core libs and dev compiler
/// resources.
final PackageNode _sdkPackageNode =
    new PackageNode(r'$sdk', getSdkPath(), DependencyType.hosted);

/// A graph of the package dependencies for an application.
class PackageGraph {
  /// The root application package.
  final PackageNode root;

  /// All [PackageNode]s indexed by package name.
  final Map<String, PackageNode> allPackages;

  PackageGraph._(this.root, Map<String, PackageNode> allPackages)
      : allPackages = new Map.unmodifiable(
            new Map<String, PackageNode>.from(allPackages)
              ..putIfAbsent(r'$sdk', () => _sdkPackageNode)) {
    if (!root.isRoot) {
      throw new ArgumentError('Root node must indicate `isRoot`');
    }
    if (allPackages.values.where((n) => n != root).any((n) => n.isRoot)) {
      throw new ArgumentError(
          'No nodes other than the root may indicate `isRoot`');
    }
  }

  /// Creates a [PackageGraph] given the [root] [PackageNode].
  factory PackageGraph.fromRoot(PackageNode root) {
    final allPackages = <String, PackageNode>{root.name: root};

    void addDeps(PackageNode package) {
      for (var dep in package.dependencies) {
        if (allPackages.containsKey(dep.name)) continue;
        allPackages[dep.name] = dep;
        addDeps(dep);
      }
    }

    addDeps(root);

    return new PackageGraph._(root, allPackages);
  }

  /// Creates a [PackageGraph] for the package whose top level directory lives
  /// at [packagePath] (no trailing slash).
  factory PackageGraph.forPath(String packagePath) {
    /// Read in the pubspec file and parse it as yaml.
    final pubspec = new File(p.join(packagePath, 'pubspec.yaml'));
    if (!pubspec.existsSync()) {
      throw 'Unable to generate package graph, no `pubspec.yaml` found. '
          'This program must be ran from the root directory of your package.';
    }
    final rootPubspec = _pubspecForPath(packagePath);
    final rootPackageName = rootPubspec['name'] as String;

    final packageLocations = _parsePackageLocations(packagePath);
    packageLocations.remove(rootPackageName);

    final dependencyTypes = _parseDependencyTypes(packagePath);

    final nodes = <String, PackageNode>{};
    final rootNode = new PackageNode(
        rootPackageName, packagePath, DependencyType.path,
        isRoot: true);
    nodes[rootPackageName] = rootNode;
    for (final packageName in packageLocations.keys) {
      if (packageName == rootPackageName) continue;
      nodes[packageName] = new PackageNode(packageName,
          packageLocations[packageName], dependencyTypes[packageName],
          isRoot: false);
    }

    rootNode.dependencies.addAll(
        _depsFromYaml(rootPubspec, isRoot: true).keys.map((n) => nodes[n]));

    final packageDependencies = _parsePackageDependencies(packageLocations);
    for (final packageName in packageDependencies.keys) {
      nodes[packageName]
          .dependencies
          .addAll(packageDependencies[packageName].map((n) => nodes[n]));
    }
    return new PackageGraph._(rootNode, nodes);
  }

  /// Creates a [PackageGraph] for the package in which you are currently
  /// running.
  factory PackageGraph.forThisPackage() => new PackageGraph.forPath('./');

  /// Shorthand to get a package by name.
  PackageNode operator [](String packageName) => allPackages[packageName];

  @override
  String toString() {
    var buffer = new StringBuffer();
    for (var package in allPackages.values) {
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
  final DependencyType dependencyType;

  /// All the packages that this package directly depends on.
  final List<PackageNode> dependencies = [];

  /// The absolute path of the current version of this package.
  final String path;

  /// Whether this node is the [PackageGraph.root].
  final bool isRoot;

  PackageNode(this.name, String path, this.dependencyType, {bool isRoot})
      : path = _toAbsolute(path),
        isRoot = isRoot ?? false;

  @override
  String toString() => '''
  $name:
    type: $dependencyType
    path: $path
    dependencies: [${dependencies.map((d) => d.name).join(', ')}]''';

  /// Converts [path] to an absolute path, returns `null` if given `null`.
  static String _toAbsolute(String path) {
    if (path == null) return null;
    return p.isAbsolute(path) ? path : p.absolute(path);
  }
}

/// Parse the `.packages` file and return a Map from package name to the file
/// location for that package.
Map<String, String> _parsePackageLocations(String rootPackagePath) {
  var packagesFile = new File(p.join(rootPackagePath, '.packages'));
  if (!packagesFile.existsSync()) {
    throw 'Unable to generate package graph, no `.packages` found. '
        'This program must be ran from the root directory of your package.';
  }
  var packageLocations = <String, String>{};
  for (final line in packagesFile.readAsLinesSync().skip(1)) {
    var firstColon = line.indexOf(':');
    var name = line.substring(0, firstColon);
    assert(line.endsWith('lib/'));
    // Start after package_name:, and strip out trailing `lib` dir.
    var uriString = line.substring(firstColon + 1, line.length - 4);
    // Strip the trailing slash, if present.
    if (uriString.endsWith('/')) {
      uriString = uriString.substring(0, uriString.length - 1);
    }
    Uri uri;
    try {
      uri = Uri.parse(uriString);
    } on FormatException catch (_) {
      /// Some types of deps don't have a scheme, and just point to a relative
      /// path.
      uri = new Uri.file(uriString);
    }
    if (!uri.isAbsolute) {
      uri = new Uri.file(p.join(rootPackagePath, uri.path));
    }
    packageLocations[name] = uri.toFilePath(windows: Platform.isWindows);
  }
  return packageLocations;
}

/// The type of dependency being used. This dictates how the package should be
/// watched for changes.
enum DependencyType { github, path, hosted }

/// Parse the `pubspec.lock` file and return a Map from package name to the type
/// of dependency.
Map<String, DependencyType> _parseDependencyTypes(String rootPackagePath) {
  final pubspecLock = new File(p.join(rootPackagePath, 'pubspec.lock'));
  if (!pubspecLock.existsSync()) {
    throw 'Unable to generate package graph, no `pubspec.lock` found. '
        'This program must be ran from the root directory of your package.';
  }
  final dependencyTypes = <String, DependencyType>{};
  final dependencies = loadYaml(pubspecLock.readAsStringSync()) as YamlMap;
  for (final packageName in dependencies['packages'].keys) {
    final source = dependencies['packages'][packageName]['source'];
    dependencyTypes[packageName as String] =
        _dependencyTypeFromSource(source as String);
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
  throw 'Unable to determine dependency type:\n$source';
}

/// Read the pubspec for each package in [packageLocations] and finds it's
/// dependencies.
Map<String, List<String>> _parsePackageDependencies(
    Map<String, String> packageLocations) {
  final dependencies = <String, List<String>>{};
  for (final packageName in packageLocations.keys) {
    final pubspec = _pubspecForPath(packageLocations[packageName]);
    final packageDeps = _depsFromYaml(pubspec);
    dependencies[packageName] = packageDeps.keys.toList();
  }
  return dependencies;
}

/// Gets the deps from a yaml file, taking into account dependency_overrides.
Map<String, dynamic> _depsFromYaml(YamlMap yaml, {bool isRoot: false}) {
  var deps = new Map<String, dynamic>.from(yaml['dependencies'] as Map ?? {});
  if (isRoot) {
    deps.addAll(new Map.from(yaml['dev_dependencies'] as Map ?? {}));
    yaml['dependency_overrides']?.forEach((dep, source) {
      deps[dep as String] = source;
    });
  }
  return deps;
}

/// Should point to the top level directory for the package.
YamlMap _pubspecForPath(String absolutePath) {
  var pubspecPath = p.join(absolutePath, 'pubspec.yaml');
  var pubspec = new File(pubspecPath);
  if (!pubspec.existsSync()) {
    throw 'Unable to generate package graph, no `$pubspecPath` found.';
  }
  return loadYaml(pubspec.readAsStringSync()) as YamlMap;
}
