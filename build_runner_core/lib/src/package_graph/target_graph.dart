// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart';
import 'package:build_config/build_config.dart';
import 'package:glob/glob.dart';

import '../generate/input_matcher.dart';
import 'package_graph.dart';

/// Like a [PackageGraph] but packages are further broken down into modules
/// based on build config.
class TargetGraph {
  /// All [TargetNode]s indexed by `"$packageName:$targetName"`.
  final Map<String, TargetNode> allModules;

  /// All [TargetNode]s by package name.
  final Map<String, List<TargetNode>> modulesByPackage;

  /// The [BuildConfig] of the root package.
  final BuildConfig rootPackageConfig;

  TargetGraph._(this.allModules, this.modulesByPackage, this.rootPackageConfig);

  static Future<TargetGraph> forPackageGraph(PackageGraph packageGraph,
      {Map<String, BuildConfig> overrideBuildConfig,
      List<String> defaultRootPackageWhitelist}) async {
    overrideBuildConfig ??= const {};
    final modulesByKey = <String, TargetNode>{};
    final modulesByPackage = <String, List<TargetNode>>{};
    BuildConfig rootPackageConfig;
    for (final package in packageGraph.allPackages.values) {
      final config = overrideBuildConfig[package.name] ??
          await _packageBuildConfig(package);
      List<String> defaultInclude;
      if (package.isRoot) {
        defaultInclude = defaultRootPackageWhitelist;
        rootPackageConfig = config;
      } else if (package.name == r'$sdk') {
        defaultInclude = const [
          'lib/dev_compiler/**.js',
          'lib/_internal/**.sum',
        ];
      } else {
        defaultInclude = const ['lib/**'];
      }
      final nodes = config.buildTargets.values.map((target) =>
          TargetNode(target, package, defaultInclude: defaultInclude));
      for (final node in nodes) {
        modulesByKey[node.target.key] = node;
        modulesByPackage.putIfAbsent(node.target.package, () => []).add(node);
      }
    }
    return TargetGraph._(modulesByKey, modulesByPackage, rootPackageConfig);
  }

  /// Whether or not [id] is included in the sources of any target in the graph.
  bool anyMatchesAsset(AssetId id) =>
      modulesByPackage[id.package]?.any((t) => t.matchesSource(id)) ?? false;
}

class TargetNode {
  final BuildTarget target;
  final PackageNode package;

  List<Glob> get sourceIncludes => _sourcesMatcher.includeGlobs;
  final InputMatcher _sourcesMatcher;

  TargetNode(this.target, this.package, {List<String> defaultInclude})
      : _sourcesMatcher =
            InputMatcher(target.sources, defaultInclude: defaultInclude);

  bool excludesSource(AssetId id) => _sourcesMatcher.excludes(id);

  bool matchesSource(AssetId id) => _sourcesMatcher.matches(id);

  @override
  String toString() => target.key;
}

Future<BuildConfig> _packageBuildConfig(PackageNode package) async {
  final dependencyNames = package.dependencies.map((n) => n.name);
  if (package.path == null) {
    return BuildConfig.useDefault(package.name, dependencyNames);
  }
  try {
    return await BuildConfig.fromBuildConfigDir(
        package.name, dependencyNames, package.path);
  } on ArgumentError catch (e) {
    throw BuildConfigParseException(package.name, e);
  }
}

class BuildConfigParseException implements Exception {
  final String packageName;
  final dynamic exception;

  BuildConfigParseException(this.packageName, this.exception);
}
