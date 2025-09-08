// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:built_collection/built_collection.dart';
import 'package:io/ansi.dart' as ansi;
import 'package:io/io.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import 'bootstrap/bootstrap.dart';
import 'bootstrap/build_script_generate.dart';
import 'build_plan/build_options.dart';
import 'build_plan/builder_application.dart';
import 'build_runner_command_line.dart';
import 'commands/build_command.dart';
import 'commands/build_runner_command.dart';
import 'commands/clean_command.dart';
import 'commands/daemon_command.dart';
import 'commands/daemon_options.dart';
import 'commands/run_command.dart';
import 'commands/run_options.dart';
import 'commands/serve_command.dart';
import 'commands/serve_options.dart';
import 'commands/test_command.dart';
import 'commands/test_options.dart';
import 'commands/watch_command.dart';
import 'constants.dart';
import 'exceptions.dart';
import 'logging/build_log.dart';

/// The `build_runner` tool.
class BuildRunner {
  final BuiltList<BuilderApplication>? builders;
  final BuiltList<String> arguments;

  late final BuildRunnerCommandLine commandLine;

  BuildRunner({
    required Iterable<String> arguments,
    required Iterable<BuilderApplication>? builders,
  }) : arguments = arguments.toBuiltList(),
       builders = builders?.toBuiltList();

  Future<int> run() async {
    try {
      return await _runOrThrow();
    } on UsageException catch (e) {
      print(ansi.red.wrap(e.message));
      print('');
      print(e.usage);
      return ExitCode.usage.code;
    } on ArgumentError // ignore: avoid_catching_errors
    catch (e) {
      print(ansi.red.wrap(e.toString()));
      return ExitCode.usage.code;
    } on CannotBuildException {
      // A message should have already been logged.
      return ExitCode.config.code;
    } on BuildScriptChangedException {
      // TODO(davidmorgan): handle cleanup where the condition is discovered,
      // not here.
      _deleteAssetGraph();
      if (_runningFromKernel) _invalidateSelf();
      return ExitCode.tempFail.code;
    } on BuildConfigChangedException {
      return ExitCode.tempFail.code;
    }
  }

  Future<int> _runOrThrow() async {
    final maybeCommandLine = await BuildRunnerCommandLine.parse(arguments);
    if (maybeCommandLine == null) return ExitCode.success.code;
    commandLine = maybeCommandLine;

    // Option parsing depends on the package name in `pubspec.yaml`.
    // Fortunately, `dart run build_runner` checks that `pubspec.yaml` is
    // present and valid, so there must be a `name`.
    final rootPackage =
        (loadYaml(File(p.join(p.current, 'pubspec.yaml')).readAsStringSync())
                as YamlMap)['name']!
            as String;

    if (commandLine.type.requiresBuilders && builders == null) {
      return await _runWithBuilders();
    }

    BuildRunnerCommand command;
    switch (commandLine.type) {
      case CommandType.build:
        command = BuildCommand(
          builders: builders!,
          buildOptions: BuildOptions.parse(
            commandLine,
            restIsBuildDirs: true,
            rootPackage: rootPackage,
          ),
        );

      case CommandType.clean:
        command = CleanCommand();

      case CommandType.daemon:
        command = DaemonCommand(
          arguments: commandLine.arguments,
          builders: builders!,
          buildOptions: BuildOptions.parse(
            commandLine,
            restIsBuildDirs: false,
            rootPackage: rootPackage,
          ),
          daemonOptions: DaemonOptions.parse(commandLine),
        );

      case CommandType.run:
        command = RunCommand(
          builders: builders!,
          buildOptions: BuildOptions.parse(
            commandLine,
            restIsBuildDirs: false,
            rootPackage: rootPackage,
          ),
          runOptions: RunOptions.parse(commandLine),
        );

      case CommandType.serve:
        command = ServeCommand(
          builders: builders!,
          buildOptions: BuildOptions.parse(
            commandLine,
            restIsBuildDirs: true,
            rootPackage: rootPackage,
          ),
          serveOptions: ServeOptions.parse(commandLine),
        );

      case CommandType.test:
        command = TestCommand(
          builders: builders!,
          buildOptions: BuildOptions.parse(
            commandLine,
            restIsBuildDirs: false,
            rootPackage: rootPackage,
          ),
          testOptions: TestOptions.parse(commandLine),
        );

      case CommandType.watch:
        command = WatchCommand(
          builders: builders!,
          buildOptions: BuildOptions.parse(
            commandLine,
            restIsBuildDirs: true,
            rootPackage: rootPackage,
          ),
        );
    }

    return await command.run();
  }

  /// Builds and runs `build_runner` with the configured builders.
  ///
  /// The nested `build_runner` invocation reaches [run] with [builders] set,
  /// so it runs the command instead of bootstrapping.
  Future<int> _runWithBuilders() async {
    buildLog.configuration = buildLog.configuration.rebuild((b) {
      b.mode = commandLine.type.buildLogMode;
    });

    // Build and run, retrying if the nested `build_runner` invocation exits
    // with exit code `tempFail`.
    while (true) {
      exitCode = await generateAndRun(
        arguments,
        experiments: commandLine.enableExperiments,
      );

      if (exitCode != ExitCode.tempFail.code) return exitCode;
    }
  }
}

/// Deletes the asset graph for the current build script from disk.
void _deleteAssetGraph() {
  final graph = File(assetGraphPath);
  if (graph.existsSync()) {
    graph.deleteSync();
  }
}

/// Deletes the current running script.
///
/// This should only happen if the current script is a snapshot, and it has
/// been invalidated.
void _invalidateSelf() {
  final kernelPath = Platform.script.toFilePath();
  final kernelFile = File(kernelPath);
  if (kernelFile.existsSync()) {
    kernelFile.renameSync('$kernelPath$scriptKernelCachedSuffix');
  }
}

bool get _runningFromKernel =>
    !Platform.script.path.endsWith(scriptKernelSuffix);
