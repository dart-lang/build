// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:build/build.dart';
import 'package:io/io.dart';
import 'package:meta/meta.dart';

import '../build_plan/builder_factories.dart';
import '../build_runner.dart';
import '../logging/build_log.dart';
import 'build_process_state.dart';
import 'parent_process.dart';

/// Methods for child processes launched with [ParentProcess.runAndSend]
/// or [ParentProcess.runAotSnapshotAndSend] to communicate with the parent.
class ChildProcess {
  /// Whether [run] is currently running.
  static bool get isRunning => isChildProcessRunning;

  /// Runs `build_runner` with [arguments] and [builderFactories].
  ///
  /// This is called by the generated build script.
  ///
  /// Exits the current process.
  static Future<Never> run(
    List<String> arguments,
    BuilderFactories builderFactories,
  ) async {
    isChildProcessRunning = true;
    buildProcessState.deserializeAndSet(await receive());
    final exitCode = await BuildRunner(
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
      if (string.contains(processSentinel)) {
        receiveBuffer.write(
          string.substring(0, string.indexOf(processSentinel)),
        );
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
    stdout.write(processSentinel);
    stdout.write(message);
    await stdout.close();
    exit(exitCode);
  }

  /// Exits indicating that a file that should exist was deleted during the
  /// build and the build cannot complete.
  ///
  /// The parent process will retry the whole command.
  static Future<Never> exitDueToAssetDeleted(AssetId id) async {
    buildLog.error('$id was unexpectedly deleted, restarting the build.');
    await ChildProcess.exitWithMessage(
      exitCode: assetDeletedExitCode,
      message: buildProcessState.serialize(),
    );
  }

  /// The exit code used to indicate "rebuild the builders".
  static int recompileBuildersExitCode = ExitCode.tempFail.code;

  /// The exit code used to indicate "try again, an asset was deleted".
  static int assetDeletedExitCode = ExitCode.data.code;
}
