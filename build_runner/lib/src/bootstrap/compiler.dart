// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as p;

import '../build_plan/build_paths.dart';
import '../constants.dart';
import 'compile_type.dart';
import 'depfile.dart';
import 'processes.dart';

/// Compiles the build script.
abstract class Compiler {
  CompileType get compileType;

  /// Checks freshness of the build script compile output.
  ///
  /// Set [digestsAreFresh] if digests were very recently updated. Then, they
  /// will be re-used from disk if possible instead of recomputed.
  FreshnessResult checkFreshness({required bool digestsAreFresh});

  /// Checks whether [path] in a dependency of the build script compile.
  ///
  /// Call [checkFreshness] first to load the depfile.
  bool isDependency(String path);

  /// Compiles the entrypoint script.
  Future<CompileResult> compile({Iterable<String>? experiments});
}

/// Common base class for process-based Dart compilers.
///
/// Handles invoking the compiler subprocess, depfile freshness checks, and
/// output cleanup.
abstract class BaseCompiler implements Compiler {
  final BuildPaths buildPaths;
  final String outputPath;
  final String depfilePath;
  final Depfile _outputDepfile;
  final String _compileSubcommand;

  BaseCompiler({
    required this.buildPaths,
    required String relativeOutputPath,
    required String relativeDepfilePath,
    required String relativeDigestPath,
    required String compileSubcommand,
  }) : outputPath = p.join(buildPaths.outputRootPath, relativeOutputPath),
       depfilePath = p.join(buildPaths.outputRootPath, relativeDepfilePath),
       _compileSubcommand = compileSubcommand,
       _outputDepfile = Depfile(
         outputPath: p.join(buildPaths.outputRootPath, relativeOutputPath),
         depfilePath: p.join(buildPaths.outputRootPath, relativeDepfilePath),
         digestPath: p.join(buildPaths.outputRootPath, relativeDigestPath),
       );

  @override
  FreshnessResult checkFreshness({required bool digestsAreFresh}) =>
      _outputDepfile.checkFreshness(digestsAreFresh: digestsAreFresh);

  @override
  bool isDependency(String path) => _outputDepfile.isDependency(path);

  /// Cleans up compiler-specific stderr messages.
  String cleanStderr(String stderr);

  @override
  Future<CompileResult> compile({Iterable<String>? experiments}) async {
    await _outputDepfile.updateStamp();
    final dart = Platform.resolvedExecutable;
    final result = await ParentProcess.run(dart, [
      'compile',
      _compileSubcommand,
      if (Isolate.packageConfigSync != null) ...[
        '--packages',
        Isolate.packageConfigSync!.toFilePath(),
      ],
      p.join(buildPaths.outputRootPath, entrypointScriptPath),
      '--output',
      outputPath,
      '--depfile',
      depfilePath,
      if (experiments != null)
        for (final experiment in experiments) '--enable-experiment=$experiment',
    ]);

    if (result.exitCode == 0) {
      final stdout = result.stdout as String;

      // Convert "unknown experiment" warnings to errors.
      if (stdout.contains('Unknown experiment:')) {
        final outputFile = File(outputPath);
        if (outputFile.existsSync()) {
          outputFile.deleteSync();
        }
        final messages = stdout
            .split('\n')
            .where((e) => e.startsWith('Unknown experiment'))
            .join('\n');
        return CompileResult(messages: messages);
      }

      // Update depfile digest on successful compile.
      _outputDepfile.writeDigest();
    }

    final stderr = cleanStderr(result.stderr as String);
    return CompileResult(messages: result.exitCode == 0 ? null : stderr);
  }
}

class CompileResult {
  final String? messages;

  CompileResult({required this.messages});

  bool get succeeded => messages == null;

  @override
  String toString() =>
      'CompileResult(succeeded: $succeeded, messages: $messages)';
}
