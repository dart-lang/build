// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:io';

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
    /// Read in the pubspec file and parse it as yaml.
    var pubspec = new File('pubspec.yaml');
    if (!pubspec.existsSync()) {
      throw 'Unable to generate package graph, no `pubspec.yaml` found.';
    }
    var yaml = loadYaml(pubspec.readAsStringSync());

    /// Read in the `.packages` file to get the locations of all packages.
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

    /// Create all [PackageNode]s for all deps.
    var nodes = <String, PackageNode>{};
    PackageNode addNodeAndDeps(YamlMap yaml, PackageDependencyType type,
        {bool isRoot: false}) {
      var name = yaml['name'];
      assert(!nodes.containsKey(name));
      var node = new PackageNode._(name, yaml['version'], type);
      nodes[name] = node;

      _depsFromYaml(yaml, withOverrides: isRoot).forEach((name, source) {
        var dep = nodes[name];
        if (dep == null) {
          var pubspec = _pubspecForUri(packageLocations[name]);
          dep = addNodeAndDeps(pubspec, _dependencyType(source));
        }
        node._dependencies.add(dep);
      });

      return node;
    }

    var root = addNodeAndDeps(yaml, PackageDependencyType.Path, isRoot: true);
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
  /// The name of the package as listed in the pubspec.yaml
  final String name;

  /// The version of the package as listed in the pubspec.yaml
  final String version;

  /// The type of dependency being used to pull in this package.
  final PackageDependencyType dependencyType;

  /// All the packages that this package directly depends on.
  final List<PackageNode> _dependencies = [];
  Iterable<PackageNode> get dependencies => _dependencies.toList();

  PackageNode._(this.name, this.version, this.dependencyType);

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
