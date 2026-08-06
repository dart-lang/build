// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:built_collection/built_collection.dart';
import 'package:io/ansi.dart' as ansi;
import 'package:io/io.dart';
import 'package:path/path.dart' as p;

import '../build_plan/build_paths.dart';
import '../build_runner_command_line.dart';
import '../commands/clean_command.dart';
import '../commands/stop_command.dart';
import '../exceptions.dart';
import '../logging/build_log.dart';
import 'bootstrapper.dart';
import 'build_process_state.dart';
import 'compile_type.dart';

/// The outer `build_runner` bootstrap runner.
///
/// This runs before builders are compiled and does not depend on
/// `package:analyzer`.
class BootstrapRunner {
  final BuiltList<String> arguments;

  BootstrapRunner({required Iterable<String> arguments})
    : arguments = arguments.toBuiltList();

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
    final commandLine = maybeCommandLine;

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

    // Take the process lock if this is the outer process. All commands except
    // `daemon` take the lock; `daemon` has its own locking.
    final buildPaths = BuildPaths.load(
      p.current,
      buildWorkspace: commandLine.workspace ?? false,
    );
    if (commandLine.type != CommandType.daemon) {
      await buildProcessState.takeLock(buildPaths);
    }

    if ((commandLine.forceAot ?? false) && (commandLine.forceJit ?? false)) {
      throw UsageException(
        'Only one compile mode can be used, '
        'got --force-aot and --force-jit.',
        commandLine.usage,
      );
    }

    final removedOptionsUsed = commandLine.removedOptionsUsed;
    if (removedOptionsUsed.isNotEmpty) {
      buildLog.warning(
        'These options have been removed and were ignored: '
        '${removedOptionsUsed.map((o) => '--$o').join(', ')}',
      );
    }

    if (commandLine.type == CommandType.clean) {
      return await CleanCommand(buildPaths).run();
    }
    if (commandLine.type == CommandType.stop) {
      return await StopCommand().run();
    }

    return await _runWithBuilders(
      buildPaths: buildPaths,
      compileStrategy: commandLine.compileStrategy,
      commandLine: commandLine,
    );
  }

  /// Builds and runs `build_runner` with the configured builders.
  Future<int> _runWithBuilders({
    required BuildPaths buildPaths,
    required CompileStrategy compileStrategy,
    required BuildRunnerCommandLine commandLine,
  }) async {
    buildLog.configuration = buildLog.configuration.rebuild((b) {
      b.mode = commandLine.type.buildLogMode;
      b.verbose = commandLine.verbose;
      b.verboseDurations = commandLine.verboseDurations;
    });

    final bootstrapper = Bootstrapper(
      buildPaths: buildPaths,
      compileStrategy: compileStrategy,
      separateBuilderCompile: commandLine.separateBuilderCompile ?? false,
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
