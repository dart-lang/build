// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:build_runner_core/build_runner_core.dart';
import 'package:io/io.dart';
import 'package:path/path.dart' as p;

import '../generate/build.dart';
import 'base_command.dart';

class RunCommand extends BuildRunnerCommand {
  @override
  String get name => 'run';

  @override
  String get description =>
      'Performs a single build on the specified targets, and executes a Dart script with the given arguments.';

  @override
  FutureOr<int> run() async {
    // Ensure that the user passed the name of a file to run.
    if (argResults.rest.isEmpty) {
      // Print the same message as Pub, for consistency's sake.
      stderr
        ..writeln('Must specify an executable to run.')
        ..writeln()
        ..writeln('Usage: pub run build_runner run <executable> [args...]')
        ..writeln(usage);
    }

    var scriptName = argResults.rest[0];

    // Create a temporary directory in which to execute the script.
    var tempPath = Directory.systemTemp
        .createTempSync('build_runner_run_script')
        .absolute
        .uri
        .toFilePath();

    try {
      var options = readOptions();
      var outputMap = options.outputMap ?? {};
      outputMap.addAll({tempPath: null});

      var result = await build(
        builderApplications,
        deleteFilesByDefault: options.deleteFilesByDefault,
        enableLowResourcesMode: options.enableLowResourcesMode,
        configKey: options.configKey,
        assumeTty: options.assumeTty,
        outputMap: outputMap,
        packageGraph: packageGraph,
        verbose: options.verbose,
        builderConfigOverrides: options.builderConfigOverrides,
        isReleaseBuild: options.isReleaseBuild,
        trackPerformance: options.trackPerformance,
        skipBuildScriptCheck: options.skipBuildScriptCheck,
        buildDirs: options.buildDirs,
        logPerformanceDir: options.logPerformanceDir,
      );

      if (result.status == BuildStatus.failure) {
        stdout.writeln('Skipping script run due to build failure');
        return result.failureType.exitCode;
      }

      // Find the path of the script to run.
      var scriptPath = p.setExtension(p.join(tempPath, scriptName), '.dart');

      // Use a completer to determine the exit code.
      var completer = new Completer<int>();

      // Create two ReceivePorts, so that we can quit when the isolate is done.
      var onExit = new ReceivePort(), onError = new ReceivePort();
      Isolate isolate;

      // On an error, kill the isolate, and rethrow the error.
      onError.listen((e) {
        isolate?.kill();
        onExit.close();
        Zone.current.handleUncaughtError(
            e[0], new StackTrace.fromString(e[1].toString()));
      });

      onExit.listen((_) {
        if (!completer.isCompleted) {
          completer.complete(ExitCode.success.code);
        }
      });

      isolate = await Isolate.spawnUri(
        p.toUri(scriptPath),
        argResults.rest.skip(1).toList(),
        null,
        onExit: onExit.sendPort,
        onError: onError.sendPort,
      );

      return await completer.future;
    } finally {
      // Clean up the output dir.
      await new Directory(tempPath).delete(recursive: true);
    }
  }
}
