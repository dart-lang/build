// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@OnPlatform({
  'windows': Skip('Directories cant be deleted while processes are still open'),
})
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:build_daemon/constants.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('DaemonCommand lock and port file race handling', () {
    late Directory tempDir;
    late String workspacePath;
    final childProcesses = <Process>[];

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('daemon_command_test_');
      workspacePath = p.join(tempDir.path, 'root_pkg');
      Directory(workspacePath).createSync(recursive: true);
      File(
        p.join(workspacePath, 'pubspec.yaml'),
      ).writeAsStringSync('name: root_pkg\nenvironment:\n  sdk: ^3.11.0\n');
      childProcesses.clear();
    });

    tearDown(() {
      for (final process in childProcesses) {
        process.kill(ProcessSignal.sigkill);
      }
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    Future<Process> startLockHolder() async {
      final scriptFile = File(p.join(tempDir.path, 'lock_holder.dart'));
      scriptFile.writeAsStringSync('''
import 'dart:convert';
import 'dart:io';
import 'package:build_daemon/constants.dart';

Future<void> main() async {
  final workspace = ${jsonEncode(workspacePath)};
  Directory(daemonWorkspace(workspace)).createSync(recursive: true);
  final lock = File(lockFilePath(workspace)).openSync(mode: FileMode.write)
    ..lockSync();
  File(versionFilePath(workspace)).writeAsStringSync(currentVersion);
  File(optionsFilePath(workspace)).writeAsStringSync('--build-mode=BuildMode.Auto');
  stdout.writeln('LOCKED');
  await stdin.transform(utf8.decoder).transform(const LineSplitter()).first;
  for (final path in [
    versionFilePath(workspace),
    optionsFilePath(workspace),
  ]) {
    try {
      File(path).deleteSync();
    } on FileSystemException {
      // Ignore if already deleted.
    }
  }
  lock.closeSync();
}
''');
      final packageConfig = (await Isolate.packageConfig)!;
      final process = await Process.start(Platform.resolvedExecutable, [
        '--packages=${packageConfig.toFilePath()}',
        scriptFile.path,
      ]);
      childProcesses.add(process);
      await process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .firstWhere((line) => line == 'LOCKED');
      return process;
    }

    Future<Stream<String>> startDaemonCommand() async {
      final scriptFile = File(p.join(tempDir.path, 'run_daemon_command.dart'));
      scriptFile.writeAsStringSync('''
import 'dart:io';
import 'package:build_daemon/constants.dart';
import 'package:build_runner/src/build_plan/build_options.dart';
import 'package:build_runner/src/build_plan/build_package.dart';
import 'package:build_runner/src/build_plan/build_packages.dart';
import 'package:build_runner/src/build_plan/build_paths.dart';
import 'package:build_runner/src/build_plan/build_phases.dart';
import 'package:build_runner/src/build_plan/builder_factories.dart';
import 'package:build_runner/src/build_plan/testing_overrides.dart';
import 'package:build_runner/src/commands/daemon_command.dart';
import 'package:build_runner/src/commands/daemon_options.dart';
import 'package:built_collection/built_collection.dart';

Future<void> main() async {
  final workspace = ${jsonEncode(workspacePath)};
  Directory.current = workspace;
  final buildPackages = BuildPackages.singlePackageBuild('root_pkg', [
    BuildPackage(
      name: 'root_pkg',
      path: workspace,
      isOutput: true,
      watch: true,
    ),
  ]);
  final command = DaemonCommand(
    builderFactories: BuilderFactories({}),
    arguments: ['--build-mode=BuildMode.Auto'].build(),
    buildOptions: BuildOptions.forTests(
      buildPaths: BuildPaths(packagePath: workspace, buildWorkspace: false),
    ),
    daemonOptions: DaemonOptions(
      buildMode: BuildMode.Auto,
      logRequests: false,
    ),
    testingOverrides: TestingOverrides(
      checkBuilderFreshness: false,
      buildPackages: buildPackages,
      builderDefinitions: BuiltList(),
      buildPhases: BuildPhases(const []),
    ),
  );
  final exitCodeFuture = command.run();
  // `Daemon(workingDirectory)` and the initial `!daemon.tryGetLock()` check run
  // synchronously before `command.run()` yields at the first poll delay.
  stdout.writeln('WAITING_FOR_LOCK');
  final exitCode = await exitCodeFuture;
  exit(exitCode);
}
''');
      final packageConfig = (await Isolate.packageConfig)!;
      final process = await Process.start(Platform.resolvedExecutable, [
        '--packages=${packageConfig.toFilePath()}',
        scriptFile.path,
      ], workingDirectory: workspacePath);
      childProcesses.add(process);
      final stdoutStream = process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .asBroadcastStream();
      process.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) => printOnFailure('[STDERR] $line'));
      return stdoutStream;
    }

    test(
      'waits for shutting-down daemon to release lock and starts new daemon',
      () async {
        // Hold lock without port file (simulating a daemon in Server.stop()
        // after deleting its port file before closing its lock).
        final lockHolder = await startLockHolder();
        final stdoutStream = await startDaemonCommand();

        final stdoutLines = <String>[];
        final waitingForLock = Completer<void>();
        final readyCompleter = Completer<void>();
        stdoutStream.listen((line) {
          if (line == 'WAITING_FOR_LOCK') {
            if (!waitingForLock.isCompleted) waitingForLock.complete();
            return;
          }
          stdoutLines.add(line);
          if (line == readyToConnectLog && !readyCompleter.isCompleted) {
            readyCompleter.complete();
          }
        });

        await waitingForLock.future;
        lockHolder.stdin.writeln('RELEASE');
        await lockHolder.exitCode;

        await readyCompleter.future.timeout(const Duration(seconds: 10));

        // When READY TO CONNECT is printed, the new daemon must have started
        // and created its port file instead of falsely reporting "Daemon is
        // already running." without a port file.
        expect(stdoutLines, contains('Starting daemon...'));
        expect(stdoutLines, isNot(contains('Daemon is already running.')));
        expect(File(portFilePath(workspacePath)).existsSync(), isTrue);
      },
    );
  });
}
