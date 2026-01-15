// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart';
import 'package:build_config/build_config.dart' hide BuildTarget;
import 'package:built_collection/built_collection.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;

import '../exceptions.dart';
import '../io/reader_writer.dart';
import '../logging/build_log.dart';
import 'build_target.dart';
import 'build_triggers.dart';
import 'input_matcher.dart';
import 'package_graph.dart';
import 'testing_overrides.dart';

/// Build configuration loaded from all `build.yaml` files in the build.
class BuildConfigs {
  static final InputMatcher _defaultMatcherForNonRoot = InputMatcher(
    const InputSet(),
    defaultInclude: defaultNonRootVisibleAssets,
  );

  /// All [BuildTarget]s indexed by `"$packageName:$targetName"`.
  final BuiltMap<String, BuildTarget> buildTargets;

  /// All [BuildTarget]s by package name.
  final BuiltListMultimap<String, BuildTarget> buildTargetsByPackage;

  /// The [BuildConfig] of the root package.
  final BuildConfig rootPackageConfig;

  // The [BuildTriggers] accumulated across all packages.
  final BuildTriggers buildTriggers;

  /// All [InputMatcher]s matching public assets by package name.
  ///
  /// If the package is non-root, only assets matched by the [InputMatcher] are
  /// included in the build.
  final BuiltMap<String, InputMatcher> _publicAssetsByPackage;

  BuildConfigs._(
    this.buildTargets,
    this.buildTargetsByPackage,
    this.rootPackageConfig,
    this.buildTriggers,
    this._publicAssetsByPackage,
  );

  /// Loads [BuildConfigs] for [packageGraph].
  ///
  /// Pass [testingOverrides] to override `reader`, `buildConfig` or
  /// `defaultRootPackageSources`.
  ///
  /// Yaml files will only be loaded if `reader` is set or is overridden
  /// in `testingOverrides`.
  static Future<BuildConfigs> load({
    required PackageGraph packageGraph,
    ReaderWriter? readerWriter,
    String? configKey,
    TestingOverrides? testingOverrides,
  }) async {
    readerWriter = testingOverrides?.readerWriter ?? readerWriter;
    try {
      return _tryForPackageGraph(
        packageGraph: packageGraph,
        readerWriter: readerWriter,
        configKey: configKey,
        testingOverrides: testingOverrides,
      );
    } on BuildConfigParseException catch (e) {
      buildLog.error(e.toString());
      throw const CannotBuildException();
    }
  }

  static Future<BuildConfigs> _tryForPackageGraph({
    required PackageGraph packageGraph,
    ReaderWriter? readerWriter,
    String? configKey,
    TestingOverrides? testingOverrides,
  }) async {
    final targetsByKey = MapBuilder<String, BuildTarget>();
    final publicAssetsByPackage = MapBuilder<String, InputMatcher>();
    final targetsByPackage = ListMultimapBuilder<String, BuildTarget>();
    late BuildConfig rootPackageConfig;
    final configs = <String, BuildConfig>{};
    final configOverrides =
        testingOverrides?.buildConfig ??
        (readerWriter == null
            ? null
            : await findBuildConfigOverrides(
              packageGraph: packageGraph,
              readerWriter: readerWriter,
              configKey: configKey,
            ));
    for (final package in packageGraph.allPackages.values) {
      final config =
          configOverrides?[package.name] ??
          await _packageBuildConfig(readerWriter, package);
      configs[package.name] = config;

      BuiltList<String> defaultInclude;
      if (package.isRoot) {
        defaultInclude =
            [
              ...(testingOverrides?.defaultRootPackageSources ??
                  defaultRootPackageSources),
              ...config.additionalPublicAssets,
            ].build();
        rootPackageConfig = config;
      } else if (package.name == r'$sdk') {
        defaultInclude =
            const ['lib/dev_compiler/**.js', 'lib/_internal/**.sum'].build();
      } else {
        defaultInclude =
            [
              ...defaultNonRootVisibleAssets,
              ...config.additionalPublicAssets,
            ].build();
      }
      publicAssetsByPackage[package.name] = InputMatcher(
        const InputSet(),
        defaultInclude:
            [
              ...defaultNonRootVisibleAssets, // public by default
              ...config.additionalPublicAssets, // user-defined public assets
            ].build(),
      );
      final nodes = config.buildTargets.values.map(
        (target) => BuildTarget(target, defaultInclude: defaultInclude),
      );
      if (package.name != r'$sdk') {
        final requiredSourcePaths = const [r'lib/$lib$'];
        final requiredRootSourcePaths = const [r'$package$', r'lib/$lib$'];
        final requiredPackagePaths =
            package.isRoot ? requiredRootSourcePaths : requiredSourcePaths;
        final requiredIds = requiredPackagePaths.map(
          (path) => AssetId(package.name, path),
        );
        final missing = _missingSources(nodes, requiredIds);
        if (missing.isNotEmpty) {
          buildLog.warning(
            'The package `${package.name}` does not include some required '
            'sources in any of its targets (see their build.yaml file).\n'
            'The missing sources are:\n'
            '${missing.map((s) => '  - ${s.path}').join('\n')}',
          );
        }
      }
      for (final node in nodes) {
        targetsByKey[node.key] = node;
        targetsByPackage.add(node.package, node);
      }
    }

    final buildTriggers = BuildTriggers.fromConfigs(configs);

    if (buildTriggers.warningsByPackage.isNotEmpty) {
      buildLog.warning(buildTriggers.renderWarnings);
    }
    return BuildConfigs._(
      targetsByKey.build(),
      targetsByPackage.build(),
      rootPackageConfig,
      buildTriggers,
      publicAssetsByPackage.build(),
    );
  }

  /// Whether or not [id] is included in the sources of any target in the graph.
  bool anyMatchesAsset(AssetId id) =>
      buildTargetsByPackage[id.package].any((t) => t.matchesSource(id));

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

Future<BuildConfig> _packageBuildConfig(
  ReaderWriter? readerWriter,
  PackageNode package,
) async {
  final dependencies = [for (final node in package.dependencies) node.name];
  try {
    final id = AssetId(package.name, 'build.yaml');
    if (readerWriter != null && await readerWriter.canRead(id)) {
      return BuildConfig.parse(
        package.name,
        dependencies,
        await readerWriter.readAsString(id),
        configYamlPath: p.join(package.path, 'build.yaml'),
      );
    } else {
      return BuildConfig.useDefault(package.name, dependencies);
    }
  } on ArgumentError // ignore: avoid_catching_errors
  catch (e) {
    throw BuildConfigParseException(package.name, e.toString());
  }
}

class BuildConfigParseException implements Exception {
  final String packageName;
  final String message;

  BuildConfigParseException(this.packageName, this.message);

  @override
  String toString() =>
      'Failed to parse `build.yaml` for $packageName: $message';
}

/// Returns the [sources] are not included in any [targets].
Iterable<AssetId> _missingSources(
  Iterable<BuildTarget> targets,
  Iterable<AssetId> sources,
) => sources.where((s) => !targets.any((t) => t.matchesSource(s)));

Future<BuiltMap<String, BuildConfig>> findBuildConfigOverrides({
  required PackageGraph packageGraph,
  required ReaderWriter? readerWriter,
  required String? configKey,
}) async {
  final configs = <String, BuildConfig>{};
  final configFiles = readerWriter!.assetFinder.find(
    Glob('*.build.yaml'),
    package: packageGraph.root.name,
  );
  await for (final id in configFiles) {
    final packageName = p.basename(id.path).split('.').first;
    final packageNode = packageGraph.allPackages[packageName];
    if (packageNode == null) {
      buildLog.warning(
        'A build config override is provided for $packageName but '
        'that package does not exist. '
        'Remove the ${p.basename(id.path)} override or add a dependency '
        'on $packageName.',
      );
      continue;
    }
    final yaml = await readerWriter.readAsString(id);
    final config = BuildConfig.parse(
      packageName,
      packageNode.dependencies.map((n) => n.name),
      yaml,
      configYamlPath: id.path,
    );
    configs[packageName] = config;
  }
  if (configKey != null) {
    final id = AssetId(packageGraph.root.name, 'build.$configKey.yaml');
    if (!await readerWriter.canRead(id)) {
      buildLog.warning('Cannot find ${id.path} for specified config.');
      throw const CannotBuildException();
    }
    final yaml = await readerWriter.readAsString(id);
    final config = BuildConfig.parse(
      packageGraph.root.name,
      packageGraph.root.dependencies.map((n) => n.name),
      yaml,
      configYamlPath: id.path,
    );
    if (config.builderDefinitions.isNotEmpty) {
      buildLog.warning(
        'Ignoring `builders` configuration in `build.$configKey.yaml` - '
        'overriding builder configuration is not supported.',
      );
    }
    configs[packageGraph.root.name] = config;
  }
  return configs.build();
}

/// The default list of files visible for non-root packages.
///
/// This is also the default list of files for targets in non-root packages when
/// an explicit include is not provided.
final BuiltList<String> defaultNonRootVisibleAssets =
    [
      'CHANGELOG*',
      'lib/**',
      'bin/**',
      'LICENSE*',
      'pubspec.yaml',
      'README*',
    ].build();

/// The default list of files to include when an explicit include is not
/// provided.
///
/// This should be a superset of [defaultNonRootVisibleAssets].
final BuiltList<String> defaultRootPackageSources =
    [
      'assets/**',
      'benchmark/**',
      'bin/**',
      'CHANGELOG*',
      'example/**',
      'lib/**',
      'test/**',
      'integration_test/**',
      'tool/**',
      'web/**',
      'node/**',
      'LICENSE*',
      'pubspec.yaml',
      'pubspec.lock',
      'README*',
      r'$package$',
    ].build();
