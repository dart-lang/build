// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import '../constants.dart';
import 'compiler.dart';
import 'depfile.dart';
import 'processes.dart';

const entrypointAotPath = '$entrypointScriptPath.aot';
const entrypointAotDepfilePath = '$entrypointScriptPath.aot.deps';
const entrypointAotDigestPath = '$entrypointScriptPath.aot.digest';

/// Compiles the build script to an AOT snapshot.
class AotCompiler implements Compiler {
  final Depfile _outputDepfile = Depfile(
    outputPath: entrypointAotPath,
    depfilePath: entrypointAotDepfilePath,
    digestPath: entrypointAotDigestPath,
  );

  @override
  FreshnessResult checkFreshness({required bool digestsAreFresh}) =>
      _outputDepfile.checkFreshness(digestsAreFresh: digestsAreFresh);

  @override
  bool isDependency(String path) => _outputDepfile.isDependency(path);

  @override
  Future<CompileResult> compile({Iterable<String>? experiments}) async {
    final dart = Platform.resolvedExecutable;
    final result = await ParentProcess.run(dart, [
      'compile',
      'aot-snapshot',
      entrypointScriptPath,
      '--output',
      entrypointAotPath,
      '--depfile',
      entrypointAotDepfilePath,
      if (experiments != null)
        for (final experiment in experiments) '--enable-experiment=$experiment',
    ]);

    if (result.exitCode == 0) {
      final stdout = result.stdout as String;

      // Convert "unknown experiment" warnings to errors.
      if (stdout.contains('Unknown experiment:')) {
        if (File(entrypointAotPath).existsSync()) {
          File(entrypointAotPath).deleteSync();
        }
        final messages = stdout
            .split('\n')
            .where((e) => e.startsWith('Unknown experiment'))
            .map((l) => '$l\n')
            .join('');
        return CompileResult(messages: messages);
      }

      // Update depfile digest on successful compile.
      _outputDepfile.writeDigest();
    }

    var stderr = result.stderr as String;
    // Tidy up the compiler output to leave just the failure.
    stderr =
        stderr
            .replaceAll('Error: AOT compilation failed', '')
            .replaceAll('Bad state: Generating AOT snapshot failed!', '')
            .trim();
    return CompileResult(messages: result.exitCode == 0 ? null : stderr);
  }
}
