// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:built_collection/built_collection.dart';
import 'package:io/io.dart';

import '../exceptions.dart';
import '../internal.dart';
import 'aot_compiler.dart';
import 'compiler.dart';
import 'depfile.dart';
import 'kernel_compiler.dart';
import 'processes.dart';

/// Generates, runs and checks freshness of the entrypoint script.
///
/// The entrypoint script calls [ChildProcess.run] passing a `BuilderFactories`
/// that knows how to instantiate all the builders that will run during the
/// build.
///
/// When the entrypoint script is compiled a "depfile" is created listing all
/// the sources it is compiled from. Then a digest is written based on the
/// contents of all these files so they can be checked for freshness later.
///
/// The entrypoint script is launched using [ParentProcess.runAndSend]
/// or [ParentProcess.runAotSnapshotAndSend] which passes initial state to it
/// and receives updated state when it exits.
class Bootstrapper {
  final bool compileAot;
  final Compiler _compiler;

  Bootstrapper({required this.compileAot})
    : _compiler = compileAot ? AotCompiler() : KernelCompiler();

  /// Generates the entrypoint script, compiles it and runs it with [arguments].
  ///
  /// If the entrypoint script exits with `ExitCode.tempFail` then regenerates
  /// it and launches it again with the same arguments.
  ///
  /// If the entrypoint exits with any other exit code, returns it.
  ///
  /// Throws `CannotBuildException` if the generated build script is invalid and
  /// cannot be compiled. The generated build script will be invalid if the
  /// build configuration points to invalid builder factories, for example if
  /// they do not exist or have the wrong types.
  Future<int> run(
    BuiltList<String> arguments, {
    required Iterable<String> jitVmArgs,
    Iterable<String>? experiments,
    bool retryCompileFailures = false,
  }) async {
    while (true) {
      // Write build script based on current config read from disk.
      await _writeBuildScript();

      // Compile if there was any change.
      if (!_compiler.checkFreshness(digestsAreFresh: false).outputIsFresh) {
        final result = await _compiler.compile(experiments: experiments);
        if (!result.succeeded) {
          final bool failedDueToMirrors;
          if (result.messages == null) {
            failedDueToMirrors = false;
          } else {
            buildLog.error(result.messages!);
            failedDueToMirrors =
                compileAot && result.messages!.contains('dart:mirrors');
          }
          if (failedDueToMirrors) {
            // TODO(davidmorgan): when build_runner manages use of AOT compile
            // this will be an automatic fallback to JIT instead of a message.
            buildLog.error(
              'Failed to compile build script. A configured builder '
              'uses `dart:mirrors` and cannot be compiled AOT. Try again '
              'without --force-aot to use a JIT compile.',
            );
          } else {
            buildLog.error(
              'Failed to compile build script. '
              'Check builder definitions and generated script '
              '$entrypointScriptPath.'
              '${retryCompileFailures ? ' Retrying.' : ''}',
            );
          }
          if (retryCompileFailures) continue;
          throw const CannotBuildException();
        }
      }

      final result =
          compileAot
              ? await ParentProcess.runAotSnapshotAndSend(
                aotSnapshot: entrypointAotPath,
                arguments: arguments,
                message: buildProcessState.serialize(),
              )
              : await ParentProcess.runAndSend(
                script: entrypointDillPath,
                arguments: arguments,
                message: buildProcessState.serialize(),
                jitVmArgs: jitVmArgs,
              );
      buildProcessState.deserializeAndSet(result.message);
      final exitCode = result.exitCode;

      if (exitCode != ExitCode.tempFail.code) {
        return exitCode;
      }
    }
  }

  /// Reads build configuration, writes the build script.
  ///
  /// Reads before write so the file is not written if there is no change.
  Future<void> _writeBuildScript() async {
    final buildScript = await generateBuildScript();
    final path = entrypointScriptPath;
    final existingBuildScript =
        File(path).existsSync() ? File(path).readAsStringSync() : null;
    if (buildScript != existingBuildScript) {
      File(path)
        ..createSync(recursive: true)
        ..writeAsStringSync(buildScript);
    }
  }

  /// Checks freshness of the compiled entrypoint script.
  ///
  /// Set [digestsAreFresh] if digests were very recently updated. Then, they
  /// will be re-used from disk if possible instead of recomputed.
  Future<FreshnessResult> checkCompileFreshness({
    required bool digestsAreFresh,
  }) async {
    if (!ChildProcess.isRunning) {
      // Any real use or realistic test has a child process; so this is only hit
      // in small tests. Return "fresh" so nothing related to recompiling is
      // triggered.
      return FreshnessResult(outputIsFresh: true);
    }
    if (digestsAreFresh) {
      final maybeResult = _compiler.checkFreshness(digestsAreFresh: true);
      if (maybeResult.outputIsFresh) return maybeResult;
      // Digest file must be missing, continue to compile.
    }
    await _writeBuildScript();
    return _compiler.checkFreshness(digestsAreFresh: false);
  }

  /// Whether [path] is a dependency of the compiled entrypoint script.
  bool isCompileDependency(String path) {
    if (!ChildProcess.isRunning) {
      // Any real use or realistic test has a child process; so this is only hit
      // in small tests. Return "not a dependency" so nothing related to
      // recompiling is triggered.
      return false;
    }
    return _compiler.isDependency(path);
  }
}
