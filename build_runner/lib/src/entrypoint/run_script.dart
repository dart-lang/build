// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:build_runner/build_runner.dart';
import 'package:build_runner_core/build_runner_core.dart';
import 'package:io/io.dart';
import 'package:path/path.dart' as p;

import 'base_command.dart';
import 'options.dart';

class RunCommand extends BuildRunnerCommand {
  @override
  String get name => 'run';

  @override
  String get description =>
      'Performs a single build on the specified targets, and executes a Dart script with the given arguments.';

  @override
  SharedOptions readOptions() {
    // The default option parser will throw if we pass additional arguments,
    // because it expects positional arguments to be build directories.
    //
    // Instead, pass an empty list, and we'll handle positional arguments ourselves.
    return new SharedOptions.fromParsedArgs(
        argResults, [], packageGraph.root.name, this);
  }

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
      return ExitCode.usage.code;
    }

    var scriptName = argResults.rest[0];
    var passedArgs = argResults.rest.skip(1).toList();
    var options = readOptions();

    // Create a temporary directory in which to execute the script.
    var tempPath = Directory.systemTemp
        .createTempSync('build_runner_run_script')
        .absolute
        .uri
        .toFilePath();

    // Create two ReceivePorts, so that we can quit when the isolate is done.
    //
    // Define these before starting the isolate, so that we can close
    // them if there is a spawn exception.
    ReceivePort onExit, onError;

    try {
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
      var packageConfigPath = p.join(tempPath, '.packages');

      // Use a completer to determine the exit code.
      var completer = new Completer<int>();

      Isolate isolate;
      onExit = new ReceivePort();
      onError = new ReceivePort();

      // On an error, kill the isolate, and rethrow the error.
      onError.listen((e) {
        isolate?.kill();
        onExit.close();
        onError.close();
        Zone.current.handleUncaughtError(
            e[0], new StackTrace.fromString(e[1].toString()));
      });

      onExit.listen((_) {
        onExit.close();
        onError.close();
        if (!completer.isCompleted) {
          completer.complete(ExitCode.success.code);
        }
      });

      isolate = await Isolate.spawnUri(
        p.toUri(scriptPath),
        passedArgs,
        null,
        onExit: onExit.sendPort,
        onError: onError.sendPort,
        packageConfig: p.toUri(packageConfigPath),
      );

      return await completer.future;
    } on IsolateSpawnException catch (e) {
      stderr.writeln(e);
      onExit?.close();
      onError?.close();
      stderr.writeln(
          'Could not spawn isolate. Ensure that your file is in a valid directory (i.e. "lib", "web", "test).');
      return ExitCode.ioError.code;
    } finally {
      // Clean up the output dir.
      var dir = new Directory(tempPath);
      if (await dir.exists()) await dir.delete(recursive: true);
    }
  }
}
