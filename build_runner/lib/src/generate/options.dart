// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';

import 'package:io/ansi.dart';
import 'package:logging/logging.dart';

import '../asset/file_based.dart';
import '../asset/reader.dart';
import '../asset/writer.dart';
import '../logging/std_io_logging.dart';
import '../package_graph/package_graph.dart';
import 'directory_watcher_factory.dart';

/// Manages setting up consistent defaults for all options and build modes.
class BuildOptions {
  // Build mode options.
  StreamSubscription logListener;
  PackageGraph packageGraph;
  RunnerAssetReader reader;
  RunnerAssetWriter writer;

  bool deleteFilesByDefault;
  bool failOnSevere;
  bool enableLowResourcesMode;
  bool assumeTty;

  // Watch mode options.
  Duration debounceDelay;
  DirectoryWatcherFactory directoryWatcherFactory;

  // For testing only, skips the build script updates check.
  bool skipBuildScriptCheck;

  // For internal use only, flipped when a severe log occurred.
  bool severeLogHandled = false;

  BuildOptions(
      {this.debounceDelay,
      this.assumeTty,
      this.deleteFilesByDefault,
      this.failOnSevere,
      this.directoryWatcherFactory,
      Level logLevel,
      onLog(LogRecord record),
      this.packageGraph,
      this.reader,
      this.writer,
      this.skipBuildScriptCheck,
      this.enableLowResourcesMode}) {
    // Set up logging
    logLevel ??= Level.INFO;

    // Invalid to have Level.OFF but want severe logs to fail the build.
    if (logLevel == Level.OFF && failOnSevere == true) {
      logLevel = Level.SEVERE;
    }

    Logger.root.level = logLevel;

    overrideAnsiOutput(assumeTty == true || ansiOutputEnabled, () {
      onLog ??= stdIOLogListener;
      logListener = Logger.root.onRecord.listen((r) {
        if (r.level == Level.SEVERE) {
          severeLogHandled = true;
        }
        onLog(r);
      });
    });

    /// Set up other defaults.
    debounceDelay ??= const Duration(milliseconds: 250);
    packageGraph ??= new PackageGraph.forThisPackage();
    reader ??= new FileBasedAssetReader(packageGraph);
    writer ??= new FileBasedAssetWriter(packageGraph);
    directoryWatcherFactory ??= defaultDirectoryWatcherFactory;
    assumeTty ??= false;
    deleteFilesByDefault ??= false;
    failOnSevere ??= false;
    skipBuildScriptCheck ??= false;
    enableLowResourcesMode ??= false;
  }
}
