// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

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
  StreamSubscription logListener;
  PackageGraph packageGraph;
  List<String> rootPackageFilesWhitelist;

  bool deleteFilesByDefault;
  bool failOnSevere;
  bool enableLowResourcesMode;
  final String outputDir;
  bool verbose;

  // Watch mode options.
  Duration debounceDelay;

  // For testing only, skips the build script updates check.
  bool skipBuildScriptCheck;

  // For internal use only, flipped when a severe log occurred.
  bool severeLogHandled = false;

  BuildOptions(BuildEnvironment environment,
      {@required this.packageGraph,
      BuildConfig rootPackageConfig,
      this.debounceDelay,
      this.deleteFilesByDefault,
      this.failOnSevere,
      Level logLevel,
      this.skipBuildScriptCheck,
      this.enableLowResourcesMode,
      this.outputDir,
      this.verbose}) {
    // Set up logging
    logLevel ??= verbose ? Level.ALL : Level.INFO;

    // Invalid to have Level.OFF but want severe logs to fail the build.
    if (logLevel == Level.OFF && failOnSevere == true) {
      logLevel = Level.SEVERE;
    }

    Logger.root.level = logLevel;

    logListener = Logger.root.onRecord.listen((r) {
      if (r.level == Level.SEVERE) {
        severeLogHandled = true;
      }
      environment.onLog(r);
    });

    /// Set up other defaults.
    debounceDelay ??= const Duration(milliseconds: 250);
    deleteFilesByDefault ??= false;
    failOnSevere ??= false;
    skipBuildScriptCheck ??= false;
    enableLowResourcesMode ??= false;
    verbose ??= false;

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
  }
}
