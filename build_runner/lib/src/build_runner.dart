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

import 'bootstrap/bootstrapper.dart';
import 'bootstrap/build_process_state.dart';
import 'bootstrap/compile_type.dart';
import 'build_plan/build_options.dart';
import 'build_plan/build_paths.dart';
import 'build_plan/builder_factories.dart';
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
import 'commands/stop_command.dart';
import 'commands/test_command.dart';
import 'commands/test_options.dart';
import 'commands/watch_command.dart';
import 'exceptions.dart';
import 'logging/build_log.dart';

/// The `build_runner` tool.
class BuildRunner {
  final BuilderFactories? builderFactories;
  final BuiltList<String> arguments;

  late final BuildRunnerCommandLine commandLine;

  BuildRunner({
    required Iterable<String> arguments,
    required this.builderFactories,
  }) : arguments = arguments.toBuiltList();

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
    }
  }

  Future<int> _runOrThrow() async {
    final maybeCommandLine = await BuildRunnerCommandLine.parse(arguments);
    if (maybeCommandLine == null) return ExitCode.success.code;
    commandLine = maybeCommandLine;

    // Option parsing depends on the package name in `pubspec.yaml`.
    // Fortunately, `dart run build_runner` checks that `pubspec.yaml` is
    // present in the current or a parent directory, and that it's valid, so
    // there must be a `name`.
    //
    // Start by changing the current directory to the package root.
    while (!File(p.join(Directory.current.path, 'pubspec.yaml')).existsSync()) {
      final parent = Directory.current.parent;
      if (parent.path == Directory.current.path) {
        throw StateError('Missing pubspec.yaml.');
      }
      Directory.current = parent;
    }
    final currentPackage =
        (loadYaml(File(p.join(p.current, 'pubspec.yaml')).readAsStringSync())
                as YamlMap)['name']!
            as String;

    // Take the process lock if this is the outer process. All commands except
    // `daemon` take the lock; `daemon` has its own locking.
    final buildPaths = BuildPaths.load(
      p.current,
      buildWorkspace: commandLine.workspace ?? false,
    );
    if (builderFactories == null && commandLine.type != CommandType.daemon) {
      await buildProcessState.takeLock(buildPaths);
    }

    if ((commandLine.forceAot ?? false) && (commandLine.forceJit ?? false)) {
      throw UsageException(
        'Only one compile mode can be used, '
        'got --force-aot and --force-jit.',
        commandLine.usage,
      );
    }

    if (commandLine.type.requiresBuilders && builderFactories == null) {
      return await _runWithBuilders(
        buildPaths: buildPaths,
        compileStrategy: commandLine.compileStrategy,
      );
    }

    final removedOptionsUsed = commandLine.removedOptionsUsed;
    if (removedOptionsUsed.isNotEmpty) {
      buildLog.warning(
        'These options have been removed and were ignored: '
        '${removedOptionsUsed.map((o) => '--$o').join(', ')}',
      );
    }

    BuildRunnerCommand command;
    switch (commandLine.type) {
      case CommandType.build:
        command = BuildCommand(
          builderFactories: builderFactories!,
          buildOptions: BuildOptions.parse(
            commandLine,
            restIsBuildDirs: true,
            currentPackage: currentPackage,
            buildPaths: buildPaths,
          ),
        );

      case CommandType.clean:
        command = CleanCommand(buildPaths);

      case CommandType.stop:
        command = StopCommand();

      case CommandType.daemon:
        command = DaemonCommand(
          arguments: commandLine.arguments,
          builderFactories: builderFactories!,
          buildOptions: BuildOptions.parse(
            commandLine,
            restIsBuildDirs: false,
            currentPackage: currentPackage,
            buildPaths: buildPaths,
          ),
          daemonOptions: DaemonOptions.parse(commandLine),
        );

      case CommandType.run:
        command = RunCommand(
          builderFactories: builderFactories!,
          buildOptions: BuildOptions.parse(
            commandLine,
            restIsBuildDirs: false,
            currentPackage: currentPackage,
            buildPaths: buildPaths,
          ),
          runOptions: RunOptions.parse(commandLine),
        );

      case CommandType.serve:
        final serveOptions = ServeOptions.parse(commandLine);
        command = ServeCommand(
          builderFactories: builderFactories!,
          buildOptions: BuildOptions.parse(
            commandLine,
            restIsBuildDirs: false,
            currentPackage: currentPackage,
            buildPaths: buildPaths,
            extraDirs: serveOptions.serveTargets.map((t) => t.dir),
          ),
          serveOptions: serveOptions,
        );

      case CommandType.test:
        command = TestCommand(
          builderFactories: builderFactories!,
          buildOptions: BuildOptions.parse(
            commandLine,
            restIsBuildDirs: false,
            currentPackage: currentPackage,
            buildPaths: buildPaths,
          ),
          testOptions: TestOptions.parse(commandLine),
        );

      case CommandType.watch:
        command = WatchCommand(
          builderFactories: builderFactories!,
          buildOptions: BuildOptions.parse(
            commandLine,
            restIsBuildDirs: true,
            currentPackage: currentPackage,
            buildPaths: buildPaths,
          ),
        );
    }

    return await command.run();
  }

  /// Builds and runs `build_runner` with the configured builders.
  ///
  /// The nested `build_runner` invocation reaches [run] with [builderFactories]
  /// set, so it runs the command instead of bootstrapping.
  Future<int> _runWithBuilders({
    required BuildPaths buildPaths,
    required CompileStrategy compileStrategy,
  }) async {
    buildLog.configuration = buildLog.configuration.rebuild((b) {
      b.mode = commandLine.type.buildLogMode;
      b.verbose = commandLine.verbose;
      b.verboseDurations = commandLine.verboseDurations;
    });

    final bootstrapper = Bootstrapper(
      buildPaths: buildPaths,
      compileStrategy: compileStrategy,
    );
    return await bootstrapper.run(
      arguments,
      dartAotPerf: commandLine.dartAotPerf ?? false,
      jitVmArgs: commandLine.jitVmArgs ?? const Iterable.empty(),
      experiments: commandLine.enableExperiments,
      retryCompileFailures:
          commandLine.type == CommandType.watch ||
          commandLine.type == CommandType.serve,
    );
  }
}
