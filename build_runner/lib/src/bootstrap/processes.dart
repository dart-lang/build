// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:meta/meta.dart';

import '../build_plan/builder_factories.dart';
import '../build_runner.dart';
import 'build_process_state.dart';

/// Methods for causing a child process to run and do work.
///
/// The child process is always waited for: there is no work done in parallel
/// with the parent.
class ParentProcess {
  /// Runs Dart [script] with [arguments], sends it [message], listens for and
  /// returns the response.
  ///
  /// When the underlying script is run with `dart run`, the [jitVmArgs] are
  /// forwarded to the Dart VM. This can be used to e.g. start the VM with
  /// debugging options.
  ///
  /// The child process should use [ChildProcess] to communicate with the
  /// parent.
  static Future<RunAndSendResult> runAndSend({
    required String script,
    required Iterable<String> arguments,
    required String message,
    required Iterable<String> jitVmArgs,
  }) async {
    final process = await _startWithReaper(Platform.resolvedExecutable, [
      'run',
      ...jitVmArgs,
      script,
      ...arguments,
    ]);

    // Copy output from the child stdout and stderr to current stdout and
    // stderr. The child response is sent on stdout after `_sentinal`, so watch
    // for the sentinal and record the response.
    var exiting = false;
    final receiveBuffer = StringBuffer();
    process.stdout.transform(utf8.decoder).listen((string) {
      if (!exiting && string.contains(_sentinel)) {
        exiting = true;
        final index = string.indexOf(_sentinel);
        stdout.write(string.substring(0, index));
        string = string.substring(index + 1);
      }
      if (exiting) {
        receiveBuffer.write(string);
      } else {
        stdout.write(string);
      }
    });
    process.stderr.transform(utf8.decoder).listen((string) {
      stderr.write(string);
    });

    // Send `message` to the child process over its stdin.
    //
    // Due to https://github.com/dart-lang/sdk/issues/61571 the end of the message
    // can't be signalled by closing stdin, that would cause a crash on Windows.
    // So send `_sentinal` instead.
    process.stdin.write(message);
    process.stdin.write(_sentinel);

    final exitCode = await process.exitCode;

    return RunAndSendResult(
      exitCode: exitCode,
      message: receiveBuffer.toString(),
    );
  }

  /// Runs a process like `Process.run` but with a reaper script so that the
  /// child process is killed if the parent process is killed.
  static Future<ProcessResult> run(
    String command,
    List<String> arguments,
  ) async {
    final process = await _startWithReaper(command, arguments);
    final stdout = StringBuffer();
    final stderr = StringBuffer();
    process.stdout.transform(utf8.decoder).listen(stdout.write);
    process.stderr.transform(utf8.decoder).listen(stderr.write);
    final exitCode = await process.exitCode;
    return ProcessResult(
      process.pid,
      exitCode,
      stdout.toString(),
      stderr.toString(),
    );
  }

  /// `Process.start` plus a reaper script so that the child process is killed
  /// if the parent process is killed.
  static Future<Process> _startWithReaper(
    String command,
    List<String> arguments,
  ) async {
    final result = await Process.start(command, arguments);
    final reaper = await _startReaper(parentPid: pid, childPid: result.pid);
    if (reaper != null) {
      result.exitCode.then<void>((_) {
        reaper.kill();
      }).ignore();
    }
    return result;
  }

  /// Starts a script that waits until [parentPid] exits then kills [childPid].
  ///
  /// Returns `null` on failure to start the script.
  ///
  /// The caller is responsible for killing the reaper if the child exits first.
  static Future<Process?> _startReaper({
    required int parentPid,
    required int childPid,
  }) async {
    try {
      if (Platform.isWindows) {
        return await Process.start('powershell', [
          // Flutter uses "-ExecutionPolicy Bypass" when it uses powershell for
          // its "update Dart" script, do the same.
          '-ExecutionPolicy',
          'Bypass',
          '-Command',
          'Wait-Process -Id $parentPid; Stop-Process -Id $childPid -Force',
        ]);
      } else {
        // The default shell on MacOS is zsh, but it also has an old version of
        // bash that is sufficient for this script.
        return await Process.start('bash', [
          '-c',
          'while kill -0 $parentPid; do sleep 1; done; kill -9 $childPid',
        ], mode: ProcessStartMode.detachedWithStdio);
      }
    } on ProcessException catch (_) {
      // Give up if `powershell` or `bash` is missing from PATH.
      return null;
    }
  }
}

/// The child process exit code and the message it sent back.
class RunAndSendResult {
  final int exitCode;
  final String message;

  RunAndSendResult({required this.exitCode, required this.message});
}

/// Methods for child processes launched with [ParentProcess.runAndSend] to
/// communicate with the parent.
class ChildProcess {
  static bool _isRunning = false;

  /// Whether [run] is currently running.
  static bool get isRunning => _isRunning;

  /// Runs `build_runner` with [arguments] and [builderFactories].
  ///
  /// This is called by the generated build script.
  ///
  /// Exits the current process.
  static Future<Never> run(
    List<String> arguments,
    BuilderFactories builderFactories,
  ) async {
    _isRunning = true;
    buildProcessState.deserializeAndSet(await receive());
    final exitCode =
        await BuildRunner(
          arguments: arguments,
          builderFactories: builderFactories,
        ).run();
    await exitWithMessage(
      exitCode: exitCode,
      message: buildProcessState.serialize(),
    );
  }

  /// Receives the message sent from the parent process.
  @visibleForTesting
  static Future<String> receive() async {
    // Due to https://github.com/dart-lang/sdk/issues/61571 the stdin subscription
    // can't be closed, that would cause a crash on Windows.
    final receiveBuffer = StringBuffer();
    final completer = Completer<void>();
    stdin.transform(utf8.decoder).listen((string) {
      if (string.contains(_sentinel)) {
        receiveBuffer.write(string.substring(0, string.indexOf(_sentinel)));
        completer.complete();
      } else {
        receiveBuffer.write(string);
      }
    });
    await completer.future;
    return receiveBuffer.toString();
  }

  /// Sends [message] to the parent process then exits with [exitCode].
  @visibleForTesting
  static Future<Never> exitWithMessage({
    required int exitCode,
    required String message,
  }) async {
    stdout.write(_sentinel);
    stdout.write(message);
    await stdout.close();
    exit(exitCode);
  }
}

// A code in the "private use" Unicode area, so it should not be in any log
// messages.
final String _sentinel = '\uf8ff';
