// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart';
import 'package:build_config/build_config.dart';
import 'package:build_resolvers/build_resolvers.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

import '../environment/build_environment.dart';
import '../package_graph/package_graph.dart';
import '../package_graph/target_graph.dart';
import 'exceptions.dart';

/// The default list of files to include when an explicit include is not
/// provided.
const List<String> defaultRootPackageWhitelist = [
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

final _logger = Logger('BuildOptions');

class LogSubscription {
  factory LogSubscription(BuildEnvironment environment,
      {bool verbose, Level logLevel}) {
    // Set up logging
    verbose ??= false;
    logLevel ??= verbose ? Level.ALL : Level.INFO;

    // Severe logs can fail the build and should always be shown.
    if (logLevel == Level.OFF) logLevel = Level.SEVERE;

    Logger.root.level = logLevel;

    var logListener = Logger.root.onRecord.listen(environment.onLog);
    return LogSubscription._(verbose, logListener);
  }

  LogSubscription._(this.verbose, this.logListener);

  final bool verbose;
  final StreamSubscription<LogRecord> logListener;
}

/// Manages setting up consistent defaults for all options and build modes.
class BuildOptions {
  // Build mode options.
  final StreamSubscription logListener;
  final PackageGraph packageGraph;

  final bool deleteFilesByDefault;
  final bool enableLowResourcesMode;
  final bool trackPerformance;
  final bool verbose;
  final List<String> buildDirs;
  final TargetGraph targetGraph;
  final Resolvers resolvers;

  /// If present, the path to a directory to write performance logs to.
  final String logPerformanceDir;

  // Watch mode options.
  Duration debounceDelay;

  // For testing only, skips the build script updates check.
  bool skipBuildScriptCheck;

  BuildOptions._({
    @required this.debounceDelay,
    @required this.deleteFilesByDefault,
    @required this.enableLowResourcesMode,
    @required this.logListener,
    @required this.packageGraph,
    @required this.skipBuildScriptCheck,
    @required this.trackPerformance,
    @required this.verbose,
    @required this.buildDirs,
    @required this.targetGraph,
    @required this.logPerformanceDir,
    @required this.resolvers,
  });

  static Future<BuildOptions> create(
    LogSubscription logSubscription, {
    Duration debounceDelay,
    bool deleteFilesByDefault,
    bool enableLowResourcesMode,
    @required PackageGraph packageGraph,
    Map<String, BuildConfig> overrideBuildConfig,
    bool skipBuildScriptCheck,
    bool trackPerformance,
    List<String> buildDirs,
    String logPerformanceDir,
    Resolvers resolvers,
  }) async {
    TargetGraph targetGraph;
    try {
      targetGraph = await TargetGraph.forPackageGraph(packageGraph,
          overrideBuildConfig: overrideBuildConfig,
          defaultRootPackageWhitelist: defaultRootPackageWhitelist);
    } on BuildConfigParseException catch (e, s) {
      _logger.severe(
          'Failed to parse `build.yaml` for ${e.packageName}.', e.exception, s);
      throw CannotBuildException();
    }

    /// Set up other defaults.
    debounceDelay ??= const Duration(milliseconds: 250);
    deleteFilesByDefault ??= false;
    skipBuildScriptCheck ??= false;
    enableLowResourcesMode ??= false;
    buildDirs ??= [];
    trackPerformance ??= false;
    if (logPerformanceDir != null) {
      // Requiring this to be under the root package allows us to use an
      // `AssetWriter` to write logs.
      if (!p.isWithin(p.current, logPerformanceDir)) {
        _logger.severe('Performance logs may only be output under the root '
            'package, but got `$logPerformanceDir` which is not.');
        throw CannotBuildException();
      }
      trackPerformance = true;
    }
    resolvers ??= AnalyzerResolvers();

    return BuildOptions._(
      debounceDelay: debounceDelay,
      deleteFilesByDefault: deleteFilesByDefault,
      enableLowResourcesMode: enableLowResourcesMode,
      logListener: logSubscription.logListener,
      packageGraph: packageGraph,
      skipBuildScriptCheck: skipBuildScriptCheck,
      trackPerformance: trackPerformance,
      verbose: logSubscription.verbose,
      buildDirs: buildDirs,
      targetGraph: targetGraph,
      logPerformanceDir: logPerformanceDir,
      resolvers: resolvers,
    );
  }
}
