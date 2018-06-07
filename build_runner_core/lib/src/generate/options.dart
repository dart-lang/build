// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build_config/build_config.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

import '../environment/build_environment.dart';
import '../package_graph/package_graph.dart';
import '../package_graph/target_graph.dart';
import 'exceptions.dart';

/// The default list of files to include when an explicit include is not
/// provided.
const List<String> defaultRootPackageWhitelist = const [
  'benchmark/**',
  'bin/**',
  'example/**',
  'lib/**',
  'test/**',
  'tool/**',
  'web/**',
  'pubspec.yaml',
  'pubspec.lock',
];

final _logger = new Logger('BuildOptions');

/// Manages setting up consistent defaults for all options and build modes.
class BuildOptions {
  // Build mode options.
  final StreamSubscription logListener;
  final PackageGraph packageGraph;

  final bool deleteFilesByDefault;
  final bool enableLowResourcesMode;
  final bool failOnSevere;
  final Map<String, String> outputMap;
  final bool trackPerformance;
  final bool verbose;
  final List<String> buildDirs;
  final TargetGraph targetGraph;

  /// If present, the path to a directory to write performance logs to.
  final String logPerformance;

  // Watch mode options.
  Duration debounceDelay;

  // For testing only, skips the build script updates check.
  bool skipBuildScriptCheck;

  BuildOptions._({
    @required this.debounceDelay,
    @required this.deleteFilesByDefault,
    @required this.enableLowResourcesMode,
    @required this.failOnSevere,
    @required this.logListener,
    @required this.outputMap,
    @required this.packageGraph,
    @required this.skipBuildScriptCheck,
    @required this.trackPerformance,
    @required this.verbose,
    @required this.buildDirs,
    @required this.targetGraph,
    @required this.logPerformance,
  });

  static Future<BuildOptions> create(
    BuildEnvironment environment, {
    Duration debounceDelay,
    bool deleteFilesByDefault,
    bool enableLowResourcesMode,
    bool failOnSevere,
    Level logLevel,
    Map<String, String> outputMap,
    @required PackageGraph packageGraph,
    Map<String, BuildConfig> overrideBuildConfig,
    bool skipBuildScriptCheck,
    bool trackPerformance,
    bool verbose,
    List<String> buildDirs,
    String logPerformance,
  }) async {
    // Set up logging
    verbose ??= false;
    logLevel ??= verbose ? Level.ALL : Level.INFO;

    // Invalid to have Level.OFF but want severe logs to fail the build.
    if (logLevel == Level.OFF && failOnSevere == true) {
      logLevel = Level.SEVERE;
    }

    Logger.root.level = logLevel;

    var logListener = Logger.root.onRecord.listen(environment.onLog);

    TargetGraph targetGraph;
    try {
      targetGraph = await TargetGraph.forPackageGraph(packageGraph,
          overrideBuildConfig: overrideBuildConfig,
          defaultRootPackageWhitelist: defaultRootPackageWhitelist);
    } on BuildConfigParseException catch (e, s) {
      _logger.severe(
          'Failed to parse `build.yaml` for ${e.packageName}.', e.exception, s);
      throw new CannotBuildException();
    }

    /// Set up other defaults.
    debounceDelay ??= const Duration(milliseconds: 250);
    deleteFilesByDefault ??= false;
    failOnSevere ??= false;
    skipBuildScriptCheck ??= false;
    enableLowResourcesMode ??= false;
    buildDirs ??= [];
    trackPerformance ??= false;
    if (logPerformance != null) {
      // Requiring this to be under the root package allows us to use an
      // `AssetWriter` to write logs.
      if (!p.isWithin(p.current, logPerformance)) {
        _logger
            .severe('--log-performance directory must be a path under the root '
                'package, but got `$logPerformance` which is not.');
        throw new CannotBuildException();
      }
      trackPerformance = true;
    }

    return new BuildOptions._(
        debounceDelay: debounceDelay,
        deleteFilesByDefault: deleteFilesByDefault,
        enableLowResourcesMode: enableLowResourcesMode,
        failOnSevere: failOnSevere,
        logListener: logListener,
        outputMap: outputMap,
        packageGraph: packageGraph,
        skipBuildScriptCheck: skipBuildScriptCheck,
        trackPerformance: trackPerformance,
        verbose: verbose,
        buildDirs: buildDirs,
        targetGraph: targetGraph,
        logPerformance: logPerformance);
  }
}
