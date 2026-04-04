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
import 'build_plan/build_options.dart';
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
import 'commands/test_command.dart';
import 'commands/test_options.dart';
import 'commands/watch_command.dart';
import 'constants.dart';
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

    // If this is the outer bootstrapping process and not a daemon command,
    // acquire the universal runner lock to prevent concurrent builds.
    if (builderFactories == null && commandLine.type != CommandType.daemon) {
      if (!_acquireLock()) {
        return ExitCode.config.code;
      }
    }

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
    final rootPackage =
        (loadYaml(File(p.join(p.current, 'pubspec.yaml')).readAsStringSync())
                as YamlMap)['name']!
            as String;

    if (commandLine.type.requiresBuilders && builderFactories == null) {
      return await _runWithBuilders(
        workspace: commandLine.workspace!,
        compileAot: commandLine.forceAot!,
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
            rootPackage: rootPackage,
          ),
        );

      case CommandType.clean:
        command = CleanCommand();

      case CommandType.daemon:
        command = DaemonCommand(
          arguments: commandLine.arguments,
          builderFactories: builderFactories!,
          buildOptions: BuildOptions.parse(
            commandLine,
            restIsBuildDirs: false,
            rootPackage: rootPackage,
          ),
          daemonOptions: DaemonOptions.parse(commandLine),
        );

      case CommandType.run:
        command = RunCommand(
          builderFactories: builderFactories!,
          buildOptions: BuildOptions.parse(
            commandLine,
            restIsBuildDirs: false,
            rootPackage: rootPackage,
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
            rootPackage: rootPackage,
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
            rootPackage: rootPackage,
          ),
          testOptions: TestOptions.parse(commandLine),
        );

      case CommandType.watch:
        command = WatchCommand(
          builderFactories: builderFactories!,
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
  /// The nested `build_runner` invocation reaches [run] with [builderFactories]
  /// set, so it runs the command instead of bootstrapping.
  Future<int> _runWithBuilders({
    required bool workspace,
    required bool compileAot,
  }) async {
    buildLog.configuration = buildLog.configuration.rebuild((b) {
      b.mode = commandLine.type.buildLogMode;
      b.verbose = commandLine.verbose;
      b.verboseDurations = commandLine.verboseDurations;
    });

    final bootstrapper = Bootstrapper(
      workspace: workspace,
      compileAot: compileAot,
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

  /// A handle to the universal lock file, if acquired by this process.
  ///
  /// TRICKY: This is kept static so that commands like `clean` can explicitly
  /// release the lock before performing destructive filesystem operations (like
  /// deleting `.dart_tool/build`) to avoid OS-level sharing violations on
  /// Windows. It also aids integration tests that interleave multiple runs.
  static RandomAccessFile? _universalLock;

  /// Explicitly releases the universal runner lock if held by this process.
  static void releaseLock() {
    _universalLock?.closeSync();
    _universalLock = null;
  }

  /// Attempts to acquire an exclusive lock on the universal build runner lock
  /// file.
  ///
  /// Returns `true` if the lock was successfully acquired, or `false` if the
  /// lock is already held by another active process.
  bool _acquireLock() {
    final lockPath = p.join(cacheDirectoryPath, 'runner.lock');
    final lockFile = File(lockPath);
    try {
      lockFile.createSync(recursive: true);
      // Open and lock exclusively. The lock is released automatically by the OS
      // when the process terminates, OR explicitly via `releaseLock()`.
      final openLock = lockFile.openSync(mode: FileMode.write);
      openLock.lockSync();

      // TRICKY: Write diagnostic metadata using the open handle itself rather
      // than opening the file again via `File.writeAsStringSync`. On Windows,
      // mandatory locking prevents opening a second handle to an exclusively
      // locked file.
      openLock.writeStringSync('''
pid: $pid
command: ${commandLine.type.name}
timestamp: ${DateTime.now().toIso8601String()}
arguments: ${arguments.join(' ')}
''');
      _universalLock = openLock;
      return true;
    } on FileSystemException {
      String metadata;
      try {
        if (lockFile.existsSync()) {
          metadata = lockFile.readAsStringSync();
        } else {
          metadata = 'Unknown process';
        }
      } catch (_) {
        metadata = 'Unknown process (metadata unreadable due to OS lock)';
      }
      print(
        ansi.red.wrap('''
Build failed: Another instance of `build_runner` is currently running in this package.

Lock held by:
$metadata
Please terminate that process before starting a new build.
'''),
      );
      return false;
    }
  }
}
