// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import '../constants.dart';
import 'compiler.dart';
import 'depfile.dart';
import 'processes.dart';

const entrypointDillPath = '$entrypointScriptPath.dill';
const entrypointDillDepfilePath = '$entrypointScriptPath.dill.deps';
const entrypointDillDigestPath = '$entrypointScriptPath.dill.digest';

/// Compiles the build script to kernel.
class KernelCompiler implements Compiler {
  final Depfile _outputDepfile = Depfile(
    outputPath: entrypointDillPath,
    depfilePath: entrypointDillDepfilePath,
    digestPath: entrypointDillDigestPath,
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
      'kernel',
      entrypointScriptPath,
      '--output',
      entrypointDillPath,
      '--depfile',
      entrypointDillDepfilePath,
      if (experiments != null)
        for (final experiment in experiments) '--enable-experiment=$experiment',
    ]);

    if (result.exitCode == 0) {
      final stdout = result.stdout as String;

      // Convert "unknown experiment" warnings to errors.
      if (stdout.contains('Unknown experiment:')) {
        if (File(entrypointDillPath).existsSync()) {
          File(entrypointDillPath).deleteSync();
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

    var stderr = result.stderr as String;
    // Tidy up the compiler output to leave just the failure.
    stderr =
        stderr.replaceAll('Bad state: Generating kernel failed!', '').trim();
    return CompileResult(messages: result.exitCode == 0 ? null : stderr);
  }
}
