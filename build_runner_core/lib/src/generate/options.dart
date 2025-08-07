// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart';
import 'package:build/experiments.dart';
import 'package:build_config/build_config.dart';
import 'package:build_resolvers/build_resolvers.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;

import '../logging/build_log.dart';
import '../package_graph/package_graph.dart';
import '../package_graph/target_graph.dart';
import 'exceptions.dart';

/// The default list of files visible for non-root packages.
///
/// This is also the default list of files for targets in non-root packages when
/// an explicit include is not provided.
const List<String> defaultNonRootVisibleAssets = [
  'CHANGELOG*',
  'lib/**',
  'bin/**',
  'LICENSE*',
  'pubspec.yaml',
  'README*',
];

/// The default list of files to include when an explicit include is not
/// provided.
///
/// This should be a superset of [defaultNonRootVisibleAssets].
const List<String> defaultRootPackageSources = [
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
];

/// Describes a set of files that should be built.
class BuildFilter {
  /// The package name glob that files must live under in order to match.
  final Glob _package;

  /// A glob for files under [_package] that must match.
  final Glob _path;

  BuildFilter(this._package, this._path);

  /// Builds a [BuildFilter] from a command line argument.
  ///
  /// Both relative paths and package: uris are supported. Relative
  /// paths are treated as relative to the [rootPackage].
  ///
  /// Globs are supported in package names and paths.
  factory BuildFilter.fromArg(String arg, String rootPackage) {
    var uri = Uri.parse(arg);
    if (uri.scheme == 'package') {
      var package = uri.pathSegments.first;
      var glob = Glob(p.url.joinAll(['lib', ...uri.pathSegments.skip(1)]));
      return BuildFilter(Glob(package), glob);
    } else if (uri.scheme.isEmpty) {
      return BuildFilter(Glob(rootPackage), Glob(uri.path));
    } else {
      throw FormatException('Unsupported scheme ${uri.scheme}', uri);
    }
  }

  /// Returns whether or not [id] mathes this filter.
  bool matches(AssetId id) =>
      _package.matches(id.package) && _path.matches(id.path);

  @override
  int get hashCode => Object.hash(
    _package.context,
    _package.pattern,
    _package.recursive,
    _path.context,
    _path.pattern,
    _path.recursive,
  );

  @override
  bool operator ==(Object other) =>
      other is BuildFilter &&
      other._path.context == _path.context &&
      other._path.pattern == _path.pattern &&
      other._path.recursive == _path.recursive &&
      other._package.context == _package.context &&
      other._package.pattern == _package.pattern &&
      other._package.recursive == _package.recursive;
}

/// Manages setting up consistent defaults for all options and build modes.
class BuildOptions {
  final bool enableLowResourcesMode;

  /// If present, the path to a directory to write performance logs to.
  final String? logPerformanceDir;

  final PackageGraph packageGraph;
  final Resolvers resolvers;
  final TargetGraph targetGraph;
  final bool trackPerformance;

  /// Watch mode options.
  Duration debounceDelay;

  /// For testing only, skips the build script updates check.
  bool skipBuildScriptCheck;

  /// Listener for when builders report unused assets.
  void Function(AssetId, Iterable<AssetId>)? reportUnusedAssetsForInput;

  BuildOptions._({
    required this.debounceDelay,
    required this.enableLowResourcesMode,
    required this.packageGraph,
    required this.skipBuildScriptCheck,
    required this.trackPerformance,
    required this.targetGraph,
    required this.logPerformanceDir,
    required this.resolvers,
    this.reportUnusedAssetsForInput,
  });

  /// Creates a [BuildOptions] with sane defaults.
  ///
  /// Pass [reader] to read `build.yaml` files, otherwise defaults are used.
  ///
  /// NOTE: If a custom [resolvers] instance is passed it must ensure that it
  /// enables [enabledExperiments] on any analysis options it creates.
  static Future<BuildOptions> create({
    required PackageGraph packageGraph,
    AssetReader? reader,
    Duration debounceDelay = const Duration(milliseconds: 250),
    bool enableLowResourcesMode = false,
    Map<String, BuildConfig> overrideBuildConfig = const {},
    bool skipBuildScriptCheck = false,
    bool trackPerformance = false,
    String? logPerformanceDir,
    Resolvers? resolvers,
    void Function(AssetId, Iterable<AssetId>)? reportUnusedAssetsForInput,
  }) async {
    TargetGraph targetGraph;
    try {
      targetGraph = await TargetGraph.forPackageGraph(
        packageGraph,
        reader: reader,
        overrideBuildConfig: overrideBuildConfig,
        defaultRootPackageSources: defaultRootPackageSources,
        requiredSourcePaths: [r'lib/$lib$'],
        requiredRootSourcePaths: [r'$package$', r'lib/$lib$'],
      );
    } on BuildConfigParseException catch (e) {
      buildLog.error(e.toString());
      throw const CannotBuildException();
    }

    /// Set up other defaults.
    if (logPerformanceDir != null) {
      // Requiring this to be under the root package allows us to use an
      // `AssetWriter` to write logs.
      if (!p.isWithin(p.current, logPerformanceDir)) {
        buildLog.error(
          'Performance logs may only be output under the root '
          'package, but got `$logPerformanceDir` which is not.',
        );
        throw const CannotBuildException();
      }
      trackPerformance = true;
    }
    resolvers ??= AnalyzerResolvers.sharedInstance;

    return BuildOptions._(
      debounceDelay: debounceDelay,
      enableLowResourcesMode: enableLowResourcesMode,
      packageGraph: packageGraph,
      skipBuildScriptCheck: skipBuildScriptCheck,
      trackPerformance: trackPerformance,
      targetGraph: targetGraph,
      logPerformanceDir: logPerformanceDir,
      resolvers: resolvers,
      reportUnusedAssetsForInput: reportUnusedAssetsForInput,
    );
  }
}
