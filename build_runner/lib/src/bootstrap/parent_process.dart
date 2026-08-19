// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:io/io.dart';
import 'package:path/path.dart' as p;

import 'powershell.dart';

// A code in the "private use" Unicode area, so it should not be in any log
// messages.
final String processSentinel = '\uf8ff';

/// The exit code used to indicate "rebuild the builders".
final int recompileBuildersExitCode = ExitCode.tempFail.code;

/// The exit code used to indicate "try again, an asset was deleted".
final int assetDeletedExitCode = ExitCode.data.code;

/// Whether a child process is currently running.
bool isChildProcessRunning = false;

/// Methods for causing a child process to run and do work.
///
/// The child process is always waited for: there is no work done in parallel
/// with the parent.
class ParentProcess {
  /// Runs Dart [script] with [arguments], sends it [message], listens for and
  /// returns the response.
  ///
  /// [script] can be a kernel file or Dart source.
  ///
  /// The [jitVmArgs] are forwarded to the Dart VM. This can be used to e.g.
  /// start the VM with debugging options.
  ///
  /// The child process should use `ChildProcess` to communicate with the
  /// parent.
  static Future<RunAndSendResult> runAndSend({
    required String script,
    required Iterable<String> arguments,
    required String message,
    required Iterable<String> jitVmArgs,
  }) async {
    return await _runAndSend(
      executable: Platform.resolvedExecutable,
      arguments: ['run', ...jitVmArgs, script, ...arguments],
      message: message,
    );
  }

  /// Runs Dart [aotSnapshot] with [arguments], sends it [message], listens for
  /// and returns the response.
  ///
  /// The child process should use `ChildProcess` to communicate with the
  /// parent.
  static Future<RunAndSendResult> runAotSnapshotAndSend({
    required String aotSnapshot,
    required Iterable<String> arguments,
    required String message,
    required bool runUnderPerf,
  }) async {
    final dartAotRuntime = p.join(
      p.dirname(Platform.resolvedExecutable),
      'dartaotruntime',
    );
    return runUnderPerf
        ? await _runAndSend(
            executable: 'perf',
            arguments: [
              'record',
              '-g',
              '--output',
              'perf.data',
              dartAotRuntime,
              aotSnapshot,
              ...arguments,
            ],
            message: message,
          )
        : await _runAndSend(
            executable: dartAotRuntime,
            arguments: [aotSnapshot, ...arguments],
            message: message,
          );
  }

  static Future<RunAndSendResult> _runAndSend({
    required String executable,
    required List<String> arguments,
    required String message,
  }) async {
    final process = await _startWithReaper(executable, arguments);

    // Copy output from the child stdout and stderr to current stdout and
    // stderr. The child response is sent on stdout after `processSentinel`,
    // so watch for the sentinel and record the response.
    var exiting = false;
    final receiveBuffer = StringBuffer();
    process.stdout.transform(utf8.decoder).listen((string) {
      if (!exiting && string.contains(processSentinel)) {
        exiting = true;
        final index = string.indexOf(processSentinel);
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
    // So send `processSentinel` instead.
    //
    // Ignore asynchronous errors that occur if the child exits early and closes
    // its stdin pipe.
    unawaited(process.stdin.done.catchError((_) {}));

    try {
      process.stdin.write(message);
      process.stdin.write(processSentinel);
    } catch (_) {
      // Writes can fail if the child process exits too quickly due to an error.
      // Just continue: the child process output and exit code signal what
      // happened.
    }

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
          ...Powershell.baseArgs,
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
