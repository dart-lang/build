// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:async/async.dart';
import 'package:build/experiments.dart';
import 'package:built_collection/built_collection.dart';
import 'package:io/io.dart';

import '../build_script_generate/build_process_state.dart';
import '../generate/build_directory.dart';
import '../logging/build_log.dart';
import '../options/testing_overrides.dart';
import '../package_graph/apply_builders.dart';
import '../package_graph/package_graph.dart';
import '../util/constants.dart';
import 'build_command.dart';
import 'build_options.dart';
import 'build_runner_command.dart';
import 'test_options.dart';

class TestCommand implements BuildRunnerCommand {
  final BuiltList<BuilderApplication> builders;
  final BuildOptions buildOptions;
  final TestOptions testOptions;
  final TestingOverrides testingOverrides;

  TestCommand({
    required this.builders,
    required this.buildOptions,
    required this.testOptions,
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
    final tempPath =
        Directory.systemTemp
            .createTempSync('build_runner_test')
            .absolute
            .uri
            .toFilePath();
    try {
      final packageGraph =
          testingOverrides.packageGraph ?? await PackageGraph.forThisPackage();
      if (!packageGraph.allPackages.containsKey('build_test')) {
        buildLog.error('''
Missing dev dependency on package:build_test, which is required to run tests.

Please update your dev_dependencies section of your pubspec.yaml:

  dev_dependencies:
    build_runner: any
    build_test: any
    # If you need to run web tests, you will also need this dependency.
    build_web_compilers: any''');
        return ExitCode.config.code;
      }

      final result =
          await BuildCommand(
            builders: builders,
            buildOptions: buildOptions.copyWith(
              buildDirs: buildOptions.buildDirs.rebuild((b) {
                b.add(
                  BuildDirectory(
                    'test',
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
        stdout.writeln('Skipping tests due to build failure');
        return result;
      }

      return await _runTests(tempPath);
    } finally {
      // Clean up the output dir.
      await Directory(tempPath).delete(recursive: true);
    }
  }

  /// Runs tests using [precompiledPath] as the precompiled test directory.
  Future<int> _runTests(String precompiledPath) async {
    stdout.writeln('Running tests...\n');
    final testProcess = await Process.start(dartBinary, [
      'run',
      'test',
      '--precompiled',
      precompiledPath,
      ...testOptions.options,
    ], mode: ProcessStartMode.inheritStdio);
    _ensureProcessExit(testProcess);
    return testProcess.exitCode;
  }
}

void _ensureProcessExit(Process process) {
  StreamSubscription<ProcessSignal>? signalsSub = _exitProcessSignals.listen((
    signal,
  ) async {
    stdout.writeln('waiting for subprocess to exit...');
  });
  process.exitCode.then((_) {
    signalsSub?.cancel();
    signalsSub = null;
  });
}

Stream<ProcessSignal> get _exitProcessSignals =>
    Platform.isWindows
        ? ProcessSignal.sigint.watch()
        : StreamGroup.merge([
          ProcessSignal.sigterm.watch(),
          ProcessSignal.sigint.watch(),
        ]);
