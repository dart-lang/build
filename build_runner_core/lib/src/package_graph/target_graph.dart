// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart';
import 'package:build_config/build_config.dart';
import 'package:glob/glob.dart';

import '../generate/input_matcher.dart';
import '../generate/options.dart' show defaultNonRootVisibleAssets;
import 'package_graph.dart';

/// Like a [PackageGraph] but packages are further broken down into modules
/// based on build config.
class TargetGraph {
  static final InputMatcher _defaultMatcherForNonRoot = InputMatcher(
    const InputSet(),
    defaultInclude: defaultNonRootVisibleAssets,
  );

  /// All [TargetNode]s indexed by `"$packageName:$targetName"`.
  final Map<String, TargetNode> allModules;

  /// All [TargetNode]s by package name.
  final Map<String, List<TargetNode>> modulesByPackage;

  /// All [InputMatcher]s matching public assets by package name.
  ///
  /// If the package is non-root, only assets matched by the [InputMatcher] are
  /// included in the build.
  final Map<String, InputMatcher> _publicAssetsByPackage;

  /// The [BuildConfig] of the root package.
  final BuildConfig rootPackageConfig;

  TargetGraph._(
    this.allModules,
    this.modulesByPackage,
    this._publicAssetsByPackage,
    this.rootPackageConfig,
  );

  /// Builds a [TargetGraph] from [packageGraph].
  ///
  /// The [overrideBuildConfig] map overrides the config for packages by name.
  ///
  /// The [defaultRootPackageSources] is the default `sources` list to use
  /// for targets in the root package.
  ///
  /// All [requiredSourcePaths] should appear in non-root packages. A warning
  /// is logged if this condition is not met.
  ///
  /// All [requiredRootSourcePaths] should appear in the root package. A
  /// warning is logged if this condition is not met.
  static Future<TargetGraph> forPackageGraph(
    PackageGraph packageGraph, {
    Map<String, BuildConfig> overrideBuildConfig = const {},
    required List<String> defaultRootPackageSources,
    List<String> requiredSourcePaths = const [],
    List<String> requiredRootSourcePaths = const [],
  }) async {
    final modulesByKey = <String, TargetNode>{};
    final publicAssetsByPackage = <String, InputMatcher>{};
    final modulesByPackage = <String, List<TargetNode>>{};
    late BuildConfig rootPackageConfig;
    for (final package in packageGraph.allPackages.values) {
      final config =
          overrideBuildConfig[package.name] ??
          await _packageBuildConfig(package);
      List<String> defaultInclude;
      if (package.isRoot) {
        defaultInclude = [
          ...defaultRootPackageSources,
          ...config.additionalPublicAssets,
        ];
        rootPackageConfig = config;
      } else if (package.name == r'$sdk') {
        defaultInclude = const [
          'lib/dev_compiler/**.js',
          'lib/_internal/**.sum',
        ];
      } else {
        defaultInclude = [
          ...defaultNonRootVisibleAssets,
          ...config.additionalPublicAssets,
        ];
      }
      publicAssetsByPackage[package.name] = InputMatcher(
        const InputSet(),
        defaultInclude: [
          ...defaultNonRootVisibleAssets, // public by default
          ...config.additionalPublicAssets, // user-defined public assets
        ],
      );
      final nodes = config.buildTargets.values.map(
        (target) => TargetNode(target, package, defaultInclude: defaultInclude),
      );
      if (package.name != r'$sdk') {
        var requiredPackagePaths =
            package.isRoot ? requiredRootSourcePaths : requiredSourcePaths;
        var requiredIds = requiredPackagePaths.map(
          (path) => AssetId(package.name, path),
        );
        var missing = _missingSources(nodes, requiredIds);
        if (missing.isNotEmpty) {
          log.warning(
            'The package `${package.name}` does not include some required '
            'sources in any of its targets (see their build.yaml file).\n'
            'The missing sources are:\n'
            '${missing.map((s) => '  - ${s.path}').join('\n')}',
          );
        }
      }
      for (final node in nodes) {
        modulesByKey[node.target.key] = node;
        modulesByPackage.putIfAbsent(node.target.package, () => []).add(node);
      }
    }
    return TargetGraph._(
      modulesByKey,
      modulesByPackage,
      publicAssetsByPackage,
      rootPackageConfig,
    );
  }

  /// Whether or not [id] is included in the sources of any target in the graph.
  bool anyMatchesAsset(AssetId id) =>
      modulesByPackage[id.package]?.any((t) => t.matchesSource(id)) ?? false;

  /// Obtains a list of glob patterns describing all valid input assets defined
  /// in the [package].
  List<String> validInputsFor(PackageNode package) {
    if (package.isRoot) {
      // There are no restrictions for the root package
      return ['**/*'];
    } else {
      // For a non-root package, valid inputs must be exposed explicitly. Note
      // that we don't allow users to exclude inputs, so we can just return the
      // including globs.
      return [
        // `_matcherForNonRoot` always returns a matcher with non-null include
        // globs.
        for (final glob in _matcherForNonRoot(package).includeGlobs!)
          glob.pattern,
      ];
    }
  }

  /// Whether the [id] is visible in a build.
  ///
  /// All assets in the root package are visible. For non-root packages, an
  /// asset is visible if it's in a conceptually public folders of a Dart
  /// package (like `lib/` or `bin/`), or if the enclosing package made that
  /// asset public by including it in [BuildConfig.additionalPublicAssets].
  ///
  /// Note that an asset being visible does not imply that it's readable too.
  /// For instance, an asset id can be visible in the build even if the
  /// referenced asset doesn't exist. Assets that aren't part of any target
  /// would also be visible without being readable.
  bool isVisibleInBuild(AssetId id, PackageNode enclosingPackage) {
    assert(id.package == enclosingPackage.name);

    // All assets in the root package are included in the build
    if (enclosingPackage.isRoot) return true;

    // For other packages, the asset must be marked as public
    return _matcherForNonRoot(enclosingPackage).matches(id);
  }

  /// Whether [id] is considered to be semantically public.
  ///
  /// By default, files in [defaultNonRootVisibleAssets] are considered public
  /// assets as they are interesting for dependent Dart packages.
  ///
  /// However, a package can add additional sources that it considers to be
  /// public (see [BuildConfig.additionalPublicAssets]). This is not typically
  /// necessary, but may be helpful to embed non-Dart packages into the Dart
  /// package ecosystem. For instance, a C library built with `build_runner` may
  /// choose to include `include/**` as a public asset.
  ///
  /// Public assets are added as default sources to the default target. They are
  /// also not considered optional outputs for hidden build phases.
  bool isPublicAsset(AssetId id) {
    final filter =
        _publicAssetsByPackage[id.package] ?? _defaultMatcherForNonRoot;
    return filter.matches(id);
  }

  InputMatcher _matcherForNonRoot(PackageNode node) {
    assert(!node.isRoot);
    return _publicAssetsByPackage[node.name] ?? _defaultMatcherForNonRoot;
  }
}

class TargetNode {
  final BuildTarget target;
  final PackageNode package;

  // Note that default includes are required for `_sourcesMatcher`, so we know
  // these are never null.
  List<Glob> get sourceIncludes => _sourcesMatcher.includeGlobs!;
  final InputMatcher _sourcesMatcher;

  TargetNode(this.target, this.package, {required List<String> defaultInclude})
    : _sourcesMatcher = InputMatcher(
        target.sources,
        defaultInclude: defaultInclude,
      );

  bool excludesSource(AssetId id) => _sourcesMatcher.excludes(id);

  bool matchesSource(AssetId id) => _sourcesMatcher.matches(id);

  @override
  String toString() => target.key;
}

Future<BuildConfig> _packageBuildConfig(PackageNode package) async {
  final dependencyNames = package.dependencies.map((n) => n.name);
  try {
    return await BuildConfig.fromBuildConfigDir(
      package.name,
      dependencyNames,
      package.path,
    );
  } on ArgumentError // ignore: avoid_catching_errors
  catch (e) {
    throw BuildConfigParseException(package.name, e);
  }
}

class BuildConfigParseException implements Exception {
  final String packageName;
  final dynamic exception;

  BuildConfigParseException(this.packageName, this.exception);
}

/// Returns the [sources] are not included in any [targets].
Iterable<AssetId> _missingSources(
  Iterable<TargetNode> targets,
  Iterable<AssetId> sources,
) => sources.where((s) => !targets.any((t) => t.matchesSource(s)));
