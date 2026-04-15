// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:built_collection/built_collection.dart';
import 'package:path/path.dart' as p;

import '../build_plan/build_paths.dart';
import '../exceptions.dart';
import '../internal.dart';
import 'aot_compiler.dart';
import 'compile_type.dart';
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
/// If `buildPaths.buildWorkspace` the `BuilderFactories` contains builders
/// applied to any package in the workspace. Otherwise, it only contains
/// builders for the current directory package and its transitive dependencies.
///
/// When the entrypoint script is compiled a "depfile" is created listing all
/// the sources it is compiled from. Then a digest is written based on the
/// contents of all these files so they can be checked for freshness later.
///
/// The entrypoint script is launched using [ParentProcess.runAndSend]
/// or [ParentProcess.runAotSnapshotAndSend] which passes initial state to it
/// and receives updated state when it exits.
class Bootstrapper {
  final BuildPaths buildPaths;
  final CompileStrategy compileStrategy;
  Compiler _compiler;

  Bootstrapper({required this.buildPaths, required this.compileStrategy})
    : _compiler = compileStrategy.initialCompileType.createCompiler(buildPaths);

  /// Generates the entrypoint script, compiles it and runs it with [arguments].
  ///
  /// If the entrypoint script exits with
  /// `ChildProcess.recompileBuildersExitCode` or
  /// `ChildProcess.assetDeletedExitCode` then regenerates it and launches it
  /// again with the same arguments.
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
    required bool dartAotPerf,
    Iterable<String>? experiments,
    bool retryCompileFailures = false,
  }) async {
    String? previousMessages;
    while (true) {
      // Write build script based on current config read from disk.
      await _writeBuildScript();

      // Compile if there was any change.
      if (!_compiler.checkFreshness(digestsAreFresh: false).outputIsFresh) {
        final result = await buildLog.logCompile(
          compileType: _compiler.compileType,
          function: () => _compiler.compile(experiments: experiments),
        );

        // When retrying: for the first failure, log the start of a new build.
        // After that, only log if the compiler output changed. The "compiling"
        // message is still shown, with a stopwatch that resets to zero every
        // time the build restarts, but no other output until the compiler
        // output changes.
        final messagesMatchPreviousMessages =
            result.messages == previousMessages;
        previousMessages = result.messages;
        if (!result.succeeded) {
          final bool failedDueToMirrors;
          if (result.messages == null) {
            failedDueToMirrors = false;
          } else {
            failedDueToMirrors =
                _compiler.compileType == CompileType.aot &&
                result.messages!.contains('dart:mirrors');
          }
          if (failedDueToMirrors) {
            if (compileStrategy == CompileStrategy.forceAot) {
              buildLog.error(result.messages!);
              buildLog.info(
                'AOT compilation failed due to dart:mirrors usage. '
                'Not falling back to JIT compilation due to --force-aot.',
              );
              throw const CannotBuildException();
            }
            buildLog.info(
              'AOT compilation failed due to dart:mirrors usage. '
              'Falling back to JIT compilation.',
            );
            _compiler = CompileType.jit.createCompiler(buildPaths);
            continue;
          } else {
            if (!messagesMatchPreviousMessages) {
              buildLog.error(result.messages!);
              buildLog.error(
                'Failed to compile build script. '
                'Check builder definitions and generated script '
                '$entrypointScriptPath.'
                '${retryCompileFailures ? ' Retrying.' : ''}',
              );

              if (retryCompileFailures) {
                buildLog.nextBuild();
              }
            }
          }
          if (retryCompileFailures && !failedDueToMirrors) continue;
          throw const CannotBuildException();
        }
      }

      // The child process needs to know how it was compiled to check its
      // freshness, so pass `--force-aot` or `--force-jit`, except for when
      // strategy is alwaysJit.
      final result =
          _compiler.compileType == CompileType.aot
              ? await ParentProcess.runAotSnapshotAndSend(
                aotSnapshot: p.join(
                  buildPaths.outputRootPath,
                  entrypointAotPath,
                ),
                arguments: [...arguments, '--force-aot'],
                message: buildProcessState.serialize(),
                runUnderPerf: dartAotPerf,
              )
              : await ParentProcess.runAndSend(
                script: p.join(buildPaths.outputRootPath, entrypointDillPath),
                arguments:
                    compileStrategy == CompileStrategy.alwaysJit
                        ? arguments.toList()
                        : [...arguments, '--force-jit'],
                message: buildProcessState.serialize(),
                jitVmArgs: jitVmArgs,
              );
      buildProcessState.deserializeAndSet(result.message);
      final exitCode = result.exitCode;

      if (exitCode != ChildProcess.recompileBuildersExitCode &&
          exitCode != ChildProcess.assetDeletedExitCode) {
        return exitCode;
      }

      buildLog.nextBuild(
        recompilingBuilders: exitCode == ChildProcess.recompileBuildersExitCode,
      );
    }
  }

  /// Reads build configuration, writes the build script.
  ///
  /// Reads before write so the file is not written if there is no change.
  Future<void> _writeBuildScript() async {
    final buildScript = await generateBuildScript(buildPaths: buildPaths);
    final path = p.join(buildPaths.outputRootPath, entrypointScriptPath);
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
