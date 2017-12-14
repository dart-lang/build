// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build_config/build_config.dart';

import 'package_graph.dart';

/// Like a [PackageGraph] but packages are further broken down into modules
/// based on build config.
class TargetGraph {
  /// All [TargetNode]s indexed by `"$packageName:$targetName"`.
  final Map<String, TargetNode> allModules;

  TargetGraph._(this.allModules);

  static Future<TargetGraph> forPackageGraph(PackageGraph packageGraph,
      {Map<String, BuildConfig> overrideBuildConfig}) async {
    overrideBuildConfig ??= const {};
    final modules = <String, TargetNode>{};
    for (final package in packageGraph.allPackages.values) {
      final config = overrideBuildConfig[package.name] ??
          await _packageBuildConfig(package);
      final nodes = config.buildTargets.values
          .map((target) => new TargetNode(target, package));
      for (final node in nodes) {
        modules[node.target.name] = node;
      }
    }
    return new TargetGraph._(modules);
  }
}

class TargetNode {
  final BuildTarget target;
  final PackageNode package;
  TargetNode(this.target, this.package);

  @override
  String toString() => '${package.name}:${target.name}';
}

Future<BuildConfig> _packageBuildConfig(PackageNode package) async {
  final dependencyNames = package.dependencies.map((n) => n.name);
  if (package.path == null) {
    return new BuildConfig.useDefault(package.name, dependencyNames);
  }
  return BuildConfig.fromBuildConfigDir(
      package.name, dependencyNames, package.path);
}
