// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:cli_util/cli_util.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// The SDK package, we filter this to the core libs and dev compiler
/// resources.
final PackageNode _sdkPackageNode = new PackageNode(r'$sdk', getSdkPath());

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
    var pubspec = new File(p.join(packagePath, 'pubspec.yaml'));
    if (!pubspec.existsSync()) {
      throw 'Unable to generate package graph, no `pubspec.yaml` found. '
          'This program must be ran from the root directory of your package.';
    }
    var rootYaml = loadYaml(pubspec.readAsStringSync()) as YamlMap;

    /// Read in the `.packages` file to get the locations of all packages.
    var packagesFile = new File(p.join(packagePath, '.packages'));
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
        uri = new Uri.file(p.join(packagePath, uri.path));
      }
      packageLocations[name] = uri.toFilePath(windows: Platform.isWindows);
    }

    /// Create all [PackageNode]s for all deps.
    var nodes = <String, PackageNode>{};
    PackageNode addNodeAndDeps(YamlMap yaml, {bool isRoot: false}) {
      var name = yaml['name'] as String;
      assert(!nodes.containsKey(name));
      var node = new PackageNode(name, packageLocations[name], isRoot: isRoot);
      nodes[name] = node;

      var deps = _depsFromYaml(yaml, isRoot: isRoot);
      for (final name in deps) {
        var dep = nodes[name];
        if (dep == null) {
          var uri = packageLocations[name];
          if (uri == null) {
            throw 'No package found for $name.';
          }
          var pubspec = _pubspecForPath(uri);
          dep = addNodeAndDeps(pubspec);
        }
        node.dependencies.add(dep);
      }

      return node;
    }

    var root = addNodeAndDeps(rootYaml, isRoot: true);
    return new PackageGraph._(root, nodes);
  }

  /// Creates a [PackageGraph] for the package in which you are currently
  /// running.
  factory PackageGraph.forThisPackage() => new PackageGraph.forPath('.');

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

  /// All the packages that this package directly depends on.
  final List<PackageNode> dependencies = [];

  /// The absolute path of the current version of this package.
  final String path;

  /// Whether this node is the [PackageGraph.root].
  final bool isRoot;

  PackageNode(this.name, String path, {bool isRoot})
      : path = _toAbsolute(path),
        isRoot = isRoot ?? false;

  @override
  String toString() => '''
  $name:
    path: $path
    dependencies: [${dependencies.map((d) => d.name).join(', ')}]''';

  /// Converts [path] to an absolute path, returns `null` if given `null`.
  static String _toAbsolute(String path) {
    if (path == null) return null;
    return p.isAbsolute(path) ? path : p.absolute(path);
  }
}

/// Gets the deps from a yaml file, taking into account dependency_overrides.
Iterable<String> _depsFromYaml(YamlMap yaml, {bool isRoot: false}) {
  var deps = new Set<String>.from((yaml['dependencies'] as Map)?.keys ?? []);
  if (isRoot) {
    deps.addAll((yaml['dev_dependencies'] as Map<String, dynamic>)?.keys ?? []);
    deps.addAll(
        (yaml['dependency_overrides'] as Map<String, dynamic>)?.keys ?? []);
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
