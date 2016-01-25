// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library build.src.package_graph.package_graph;

import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

/// A graph of the package dependencies for an application.
class PackageGraph {
  /// The root application package.
  final PackageNode root;

  /// All the package dependencies of [root], transitive and direct.
  Set<PackageNode> get allPackages {
    var seen = new Set<PackageNode>()..add(root);

    void addDeps(PackageNode package) {
      for (var dep in package.dependencies) {
        if (seen.contains(dep)) continue;
        seen.add(dep);
        addDeps(dep);
      }
    }
    addDeps(root);

    return seen;
  }

  PackageGraph._(this.root);

  /// Creates a [PackageGraph] for the package in which you are currently
  /// running.
  factory PackageGraph.forThisPackage() {
    var pubspec = new File('pubspec.yaml');
    if (!pubspec.existsSync()) {
      throw 'Unable to generate package graph, no `pubspec.yaml` found.';
    }
    var yaml = loadYaml(pubspec.readAsStringSync());

    var packagesFile = new File('.packages');
    if (!packagesFile.existsSync()) {
      throw 'Unable to generate package graph, no `.packages` found.';
    }
    var packageLocations = <String, Uri>{};
    packagesFile.readAsLinesSync().skip(1).forEach((line) {
      var firstColon = line.indexOf(':');
      var name = line.substring(0, firstColon);
      var uriString = line.substring(firstColon + 1);
      try {
        packageLocations[name] = Uri.parse(uriString);
      } on FormatException catch (_) {
        /// Some types of deps don't have a scheme, and just point to a relative
        /// path.
        packageLocations[name] = new Uri.file(uriString);
      }
    });

    var nodes = <String, PackageNode>{};
    var root = new PackageNode.forPubspec(
        yaml, PackageDependencyType.Path, nodes, packageLocations,
        isRoot: true);

    return new PackageGraph._(root);
  }

  String toString() {
    var buffer = new StringBuffer();
    for (var package in allPackages) {
      buffer.writeln('$package');
    }
    return buffer.toString();
  }
}

/// A node in a [PackageGraph].
class PackageNode {
  final String name;

  final String version;

  final PackageDependencyType dependencyType;

  final List<PackageNode> _dependencies = [];
  Iterable<PackageNode> get dependencies => _dependencies.toList();

  PackageNode._(this.name, this.version, this.dependencyType);

  factory PackageNode.forPubspec(YamlMap yaml, PackageDependencyType type,
      Map<String, PackageNode> nodes, Map<String, Uri> packageLocations,
      {bool isRoot: false}) {
    var node = new PackageNode._(yaml['name'], yaml['version'], type);
    assert(!nodes.containsKey(node.name));
    nodes[node.name] = node;
    var deps = _depsFromYaml(yaml, withOverrides: isRoot);

    deps.forEach((name, source) {
      var dep = nodes[name];
      if (dep == null) {
        var pubspec = _pubspecForUri(packageLocations[name]);
        dep = new PackageNode.forPubspec(
            pubspec, _dependencyType(source), nodes, packageLocations);
        nodes[name] = dep;
      }
      node._dependencies.add(dep);
    });

    return node;
  }

  String toString() => '''
  $name:
    version: $version
    type: $dependencyType
    dependencies: [${dependencies.map((d) => d.name).join(', ')}]''';
}

/// The type of dependency being used. This dictates how the package should be
/// watched for changes.
enum PackageDependencyType { Pub, Github, Path, }

PackageDependencyType _dependencyType(source) {
  if (source is String) return PackageDependencyType.Pub;

  assert(source is YamlMap);
  assert(source.keys.length == 1);

  var typeString = source.keys.first;
  switch (typeString) {
    case 'git':
      return PackageDependencyType.Github;
    case 'path':
      return PackageDependencyType.Path;
    default:
      throw 'Unrecognized package dependency type `$typeString`';
  }
}

/// Gets the deps from a yaml file, taking into account dependency_overrides.
Map<String, YamlMap> _depsFromYaml(YamlMap yaml, {bool withOverrides: false}) {
  var deps = new Map.from(yaml['dependencies'] as YamlMap ?? {});
  if (withOverrides) {
    yaml['dependency_overrides']?.forEach((dep, source) {
      deps[dep] = source;
    });
  }
  return deps;
}

/// [uri] should be directly from a `.packages` file, and points to the `lib`
/// dir.
YamlMap _pubspecForUri(Uri uri) {
  var libPath = uri.toFilePath();
  assert(libPath.endsWith('lib/'));
  var pubspecPath =
      libPath.replaceRange(libPath.length - 4, libPath.length, 'pubspec.yaml');

  var pubspec = new File(pubspecPath);
  if (!pubspec.existsSync()) {
    throw 'Unable to generate package graph, no `$pubspecPath` found.';
  }
  return loadYaml(pubspec.readAsStringSync());
}
