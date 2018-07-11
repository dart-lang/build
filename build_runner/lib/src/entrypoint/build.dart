// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build_runner_core/build_runner_core.dart';
import 'package:io/io.dart';

import '../generate/build.dart';
import 'base_command.dart';

/// A command that does a single build and then exits.
class BuildCommand extends BuildRunnerCommand {
  @override
  String get invocation => '${super.invocation} [directories]';

  @override
  String get name => 'build';

  @override
  String get description =>
      'Performs a single build on the specified targets and then exits.';

  @override
  Future<int> run() async {
    var options = readOptions();
    var result = await build(
      builderApplications,
      deleteFilesByDefault: options.deleteFilesByDefault,
      enableLowResourcesMode: options.enableLowResourcesMode,
      configKey: options.configKey,
      assumeTty: options.assumeTty,
      outputMap: options.outputMap,
      outputSymlinksOnly: options.outputSymlinksOnly,
      packageGraph: packageGraph,
      verbose: options.verbose,
      builderConfigOverrides: options.builderConfigOverrides,
      isReleaseBuild: options.isReleaseBuild,
      trackPerformance: options.trackPerformance,
      skipBuildScriptCheck: options.skipBuildScriptCheck,
      buildDirs: options.buildDirs,
      logPerformanceDir: options.logPerformanceDir,
    );
    if (result.status == BuildStatus.success) {
      return ExitCode.success.code;
    } else {
      return result.failureType.exitCode;
    }
  }
}
