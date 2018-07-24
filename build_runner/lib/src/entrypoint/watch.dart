// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:io/io.dart';

import '../generate/build.dart';
import 'base_command.dart';

/// A command that watches the file system for updates and rebuilds as
/// appropriate.
class WatchCommand extends BuildRunnerCommand {
  @override
  String get invocation => '${super.invocation} [directories]';

  @override
  String get name => 'watch';

  @override
  String get description =>
      'Builds the specified targets, watching the file system for updates and '
      'rebuilding as appropriate.';

  @override
  Future<int> run() async {
    var options = readOptions();
    var handler = await watch(
      builderApplications,
      deleteFilesByDefault: options.deleteFilesByDefault,
      enableLowResourcesMode: options.enableLowResourcesMode,
      configKey: options.configKey,
      assumeTty: options.assumeTty,
      outputMap: options.outputMap,
      outputSymlinksOnly: options.outputSymlinksOnly,
      packageGraph: packageGraph,
      trackPerformance: options.trackPerformance,
      skipBuildScriptCheck: options.skipBuildScriptCheck,
      verbose: options.verbose,
      builderConfigOverrides: options.builderConfigOverrides,
      isReleaseBuild: options.isReleaseBuild,
      buildDirs: options.buildDirs,
      logPerformanceDir: options.logPerformanceDir,
    );
    if (handler == null) return ExitCode.config.code;

    await handler.currentBuild;
    await handler.buildResults.drain();
    return ExitCode.success.code;
  }
}
