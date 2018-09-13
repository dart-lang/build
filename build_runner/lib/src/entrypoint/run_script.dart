// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:args/command_runner.dart';
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
      'Performs a single build, and executes a Dart script with the given arguments.';

  @override
  String get invocation =>
      '${super.invocation.replaceFirst('[arguments]', '[build-arguments]')} '
      '<executable> [-- [script-arguments]]';

  @override
  SharedOptions readOptions() {
    // This command doesn't allow specifying directories to build, instead it
    // always builds the `test` directory.
    //
    // Here we validate that [argResults.rest] is exactly equal to all the
    // arguments after the `--`.
    if (argResults.rest.isNotEmpty) {
      void throwUsageException() {
        throw new UsageException(
            'The `run` command does not support positional args before the, '
            '`--` separator, which should separate build args from script args.',
            usage);
      }

      var separatorPos = argResults.arguments.indexOf('--');
      if (separatorPos < 0) {
        throwUsageException();
      }
      var expectedRest = argResults.arguments.skip(separatorPos + 1).toList();
      if (argResults.rest.length != expectedRest.length) {
        throwUsageException();
      }
      for (var i = 0; i < argResults.rest.length; i++) {
        if (expectedRest[i] != argResults.rest[i]) {
          throwUsageException();
        }
      }
    }

    return SharedOptions.fromParsedArgs(
        argResults, [], packageGraph.root.name, this);
  }

  @override
  FutureOr<int> run() async {
    // Ensure that the user passed the name of a file to run.
    if (argResults.rest.isEmpty) {
      logger..severe('Must specify an executable to run.')..severe(usage);
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

    // Use a completer to determine the exit code.
    var exitCodeCompleter = new Completer<int>();

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
        logger.warning('Skipping script run due to build failure');
        return result.failureType.exitCode;
      }

      // Find the path of the script to run.
      var scriptPath = p.setExtension(p.join(tempPath, scriptName), '.dart');
      var packageConfigPath = p.join(tempPath, '.packages');

      Isolate isolate;
      onExit = new ReceivePort();
      onError = new ReceivePort();

      // On an error, kill the isolate, and rethrow the error.
      onError.listen((e) {
        isolate?.kill();
        onExit.close();
        onError.close();
        logger.severe('Unhandled error from script: $scriptName', e[0],
            new StackTrace.fromString(e[1].toString()));
      });

      isolate = await Isolate.spawnUri(
        p.toUri(scriptPath),
        passedArgs,
        null,
        onExit: onExit.sendPort,
        onError: onError.sendPort,
        packageConfig: p.toUri(packageConfigPath),
      );

      return await exitCodeCompleter.future;
    } on IsolateSpawnException catch (e) {
      logger.severe(
          'Could not spawn isolate. Ensure that your file is in a valid directory (i.e. "bin", "benchmark", "example", "test", "tool").',
          e);
      return ExitCode.ioError.code;
    } finally {
      // Clean up the output dir.
      var dir = new Directory(tempPath);
      if (await dir.exists()) await dir.delete(recursive: true);

      onExit?.close();
      onError?.close();
      if (!exitCodeCompleter.isCompleted) {
        exitCodeCompleter.complete(ExitCode.success.code);
      }
    }
  }
}
