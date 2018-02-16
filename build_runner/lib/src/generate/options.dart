// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

import 'package:build_config/build_config.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

import '../environment/build_environment.dart';
import '../package_graph/package_graph.dart';

const List<String> _defaultRootPackageWhitelist = const [
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

/// Manages setting up consistent defaults for all options and build modes.
class BuildOptions {
  // Build mode options.
  final StreamSubscription logListener;
  final PackageGraph packageGraph;
  final List<String> rootPackageFilesWhitelist;

  final String configKey; // May be null.
  final bool deleteFilesByDefault;
  final bool enableLowResourcesMode;
  final bool failOnSevere;
  final String outputDir;
  final bool trackPerformance;
  final bool verbose;

  // Watch mode options.
  Duration debounceDelay;

  // For testing only, skips the build script updates check.
  bool skipBuildScriptCheck;

  BuildOptions._(
      {@required this.configKey,
      @required this.debounceDelay,
      @required this.deleteFilesByDefault,
      @required this.enableLowResourcesMode,
      @required this.failOnSevere,
      @required this.logListener,
      @required this.outputDir,
      @required this.packageGraph,
      @required List<String> rootPackageFilesWhitelist,
      @required this.skipBuildScriptCheck,
      @required this.trackPerformance,
      @required this.verbose})
      : this.rootPackageFilesWhitelist =
            new UnmodifiableListView(rootPackageFilesWhitelist);

  factory BuildOptions(BuildEnvironment environment,
      {String configKey,
      Duration debounceDelay,
      bool deleteFilesByDefault,
      bool enableLowResourcesMode,
      bool failOnSevere,
      Level logLevel,
      String outputDir,
      @required PackageGraph packageGraph,
      BuildConfig rootPackageConfig,
      bool skipBuildScriptCheck,
      bool trackPerformance,
      bool verbose}) {
    // Set up logging
    verbose ??= false;
    logLevel ??= verbose ? Level.ALL : Level.INFO;

    // Invalid to have Level.OFF but want severe logs to fail the build.
    if (logLevel == Level.OFF && failOnSevere == true) {
      logLevel = Level.SEVERE;
    }

    Logger.root.level = logLevel;

    var logListener = Logger.root.onRecord.listen(environment.onLog);

    /// Set up other defaults.
    debounceDelay ??= const Duration(milliseconds: 250);
    deleteFilesByDefault ??= false;
    failOnSevere ??= false;
    skipBuildScriptCheck ??= false;
    enableLowResourcesMode ??= false;
    trackPerformance ??= false;

    List<String> rootPackageFilesWhitelist;
    if (rootPackageConfig == null ||
        (rootPackageConfig.buildTargets.length == 1 &&
            rootPackageConfig.buildTargets.values.single.sources.include ==
                null)) {
      rootPackageFilesWhitelist = _defaultRootPackageWhitelist;
    } else {
      rootPackageFilesWhitelist = rootPackageConfig.buildTargets.values
          .expand((target) => target.sources.include)
          .toList();
    }
    return new BuildOptions._(
        configKey: configKey,
        debounceDelay: debounceDelay,
        deleteFilesByDefault: deleteFilesByDefault,
        enableLowResourcesMode: enableLowResourcesMode,
        failOnSevere: failOnSevere,
        logListener: logListener,
        outputDir: outputDir,
        packageGraph: packageGraph,
        rootPackageFilesWhitelist: rootPackageFilesWhitelist,
        skipBuildScriptCheck: skipBuildScriptCheck,
        trackPerformance: trackPerformance,
        verbose: verbose);
  }
}
