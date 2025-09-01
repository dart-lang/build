// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:build/experiments.dart';
import 'package:build_runner_core/build_runner_core.dart';
import 'package:built_collection/built_collection.dart';
import 'package:io/io.dart';
import 'package:path/path.dart' as p;

import '../build_script_generate/build_process_state.dart';
import 'build_command.dart';
import 'build_options.dart';
import 'build_runner_command.dart';
import 'run_options.dart';

class RunCommand implements BuildRunnerCommand {
  final BuiltList<BuilderApplication> builders;
  final BuildOptions buildOptions;
  final RunOptions runOptions;
  final TestingOverrides testingOverrides;

  RunCommand({
    required this.builders,
    required this.buildOptions,
    required this.runOptions,
    this.testingOverrides = const TestingOverrides(),
  });

  @override
  Future<int> run() =>
      withEnabledExperiments(_run, buildOptions.enableExperiments.asList());

  Future<int> _run() async {
    buildLog.configuration = buildLog.configuration.rebuild((b) {
      b.mode = BuildLogMode.build;
      b.verbose = buildOptions.verbose;
      b.onLog = testingOverrides.onLog;
    });

    // Ensure the extension is .dart.
    if (p.extension(runOptions.script) != '.dart') {
      buildLog.error(
        '${runOptions.script} is not a valid Dart file and cannot be run in '
        'the VM.',
      );
      return ExitCode.usage.code;
    }

    // Create a temporary directory in which to execute the script.
    final tempPath =
        Directory.systemTemp
            .createTempSync('build_runner_run_script')
            .absolute
            .uri
            .toFilePath();

    // Use a completer to determine the exit code.
    var exitCodeCompleter = Completer<int>();

    final result =
        await BuildCommand(
          builders: builders,
          buildOptions: buildOptions.copyWith(
            buildDirs: buildOptions.buildDirs.rebuild((b) {
              b.add(
                BuildDirectory(
                  '',
                  outputLocation: OutputLocation(
                    tempPath,
                    useSymlinks: buildOptions.outputSymlinksOnly,
                    hoist: false,
                  ),
                ),
              );
            }),
          ),
          testingOverrides: testingOverrides,
        ).run();

    if (result != ExitCode.success.code) {
      buildLog.warning('Skipping script run due to build failure.');
      return result;
    }

    // Find the path of the script to run.
    var scriptPath = p.join(tempPath, runOptions.script);
    var packageConfigPath = p.join(tempPath, '.dart_tool/package_config.json');

    // Create two ReceivePorts, so that we can quit when the isolate is done.
    //
    // Define these before starting the isolate, so that we can close
    // them if there is a spawn exception.
    ReceivePort? onExit;
    ReceivePort? onError;

    onExit = ReceivePort();
    onError = ReceivePort();

    // Cleanup after exit.
    onExit.listen((_) {
      // If no error was thrown, return 0.
      if (!exitCodeCompleter.isCompleted) exitCodeCompleter.complete(0);
    });

    // On an error, kill the isolate, and log the error.
    onError.listen((e) {
      e = e as List<Object?>;
      onExit?.close();
      onError?.close();
      buildLog.error(
        buildLog.renderThrowable(
          'Unhandled error from script: ${runOptions.script}',
          e[0],
          StackTrace.fromString(e[1].toString()),
        ),
      );
      if (!exitCodeCompleter.isCompleted) exitCodeCompleter.complete(1);
    });

    try {
      await Isolate.spawnUri(
        p.toUri(scriptPath),
        runOptions.options.asList(),
        null,
        errorsAreFatal: true,
        onExit: onExit.sendPort,
        onError: onError.sendPort,
        packageConfig: p.toUri(packageConfigPath),
      );

      return await exitCodeCompleter.future;
    } on IsolateSpawnException catch (e) {
      buildLog.error(
        buildLog.renderThrowable(
          'Could not spawn isolate. Ensure that your file is in a valid '
          'directory (i.e. "bin", "benchmark", "example", "test", "tool").',
          e,
        ),
      );
      return ExitCode.ioError.code;
    } finally {
      // Clean up the output dir.
      var dir = Directory(tempPath);
      if (await dir.exists()) await dir.delete(recursive: true);

      onExit.close();
      onError.close();
      if (!exitCodeCompleter.isCompleted) {
        exitCodeCompleter.complete(ExitCode.success.code);
      }
    }
  }
}
