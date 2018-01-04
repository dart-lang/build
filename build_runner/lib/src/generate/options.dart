// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:logging/logging.dart';

import '../environment/build_environment.dart';
import '../package_graph/package_graph.dart';

/// Manages setting up consistent defaults for all options and build modes.
class BuildOptions {
  // Build mode options.
  StreamSubscription logListener;
  PackageGraph packageGraph;

  bool deleteFilesByDefault;
  bool failOnSevere;
  bool enableLowResourcesMode;
  final String outputDir;

  // Watch mode options.
  Duration debounceDelay;

  // For testing only, skips the build script updates check.
  bool skipBuildScriptCheck;

  // For internal use only, flipped when a severe log occurred.
  bool severeLogHandled = false;

  BuildOptions(BuildEnvironment environment,
      {this.debounceDelay,
      this.deleteFilesByDefault,
      this.failOnSevere,
      Level logLevel,
      this.packageGraph,
      this.skipBuildScriptCheck,
      this.enableLowResourcesMode,
      this.outputDir}) {
    // Set up logging
    logLevel ??= Level.INFO;

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
    packageGraph ??= new PackageGraph.forThisPackage();
    deleteFilesByDefault ??= false;
    failOnSevere ??= false;
    skipBuildScriptCheck ??= false;
    enableLowResourcesMode ??= false;
  }
}
