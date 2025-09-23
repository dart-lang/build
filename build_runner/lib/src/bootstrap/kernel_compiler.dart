// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'depfile.dart';
import 'processes.dart';

/// Compiles the build script to kernel.
class KernelCompiler {
  final Depfile _outputDepfile = Depfile(
    depfilePath: '.dart_tool/build/entrypoint/build.dart.dill.deps',
    digestPath: '.dart_tool/build/entrypoint/build.dart.dill.digest',
  );

  /// Checks freshness of the build script compiled kernel.
  FreshnessResult checkFreshness() => _outputDepfile.checkFreshness();

  /// Checks whether [path] in a dependency of the build script compiled kernel.
  ///
  /// Call [checkFreshness] first to load the depfile.
  bool isDependency(String path) => _outputDepfile.isDependency(path);

  /// Compiles the entrypoint script to kernel.
  Future<CompileResult> compile({Iterable<String>? experiments}) async {
    final dart = Platform.resolvedExecutable;
    final result = await ParentProcess.run(dart, [
      'compile',
      'kernel',
      '.dart_tool/build/entrypoint/build.dart',
      '--output',
      '.dart_tool/build/entrypoint/build.dart.dill',
      '--depfile',
      '.dart_tool/build/entrypoint/build.dart.dill.deps',
      if (experiments != null)
        for (final experiment in experiments) '--enable-experiment=$experiment',
    ]);

    if (result.exitCode == 0) {
      final stdout = result.stdout as String;

      // Convert "unknown experiment" warnings to errors.
      if (stdout.contains('Unknown experiment:')) {
        if (File('.dart_tool/build/entrypoint/build.dart.dill').existsSync()) {
          File('.dart_tool/build/entrypoint/build.dart.dill').deleteSync();
        }
        final messages = stdout
            .split('\n')
            .where((e) => e.startsWith('Unknown experiment'))
            .map((l) => '$l\n')
            .join('');
        return CompileResult(messages: messages);
      }
    }

    if (result.exitCode == 0) {
      _outputDepfile.writeDigest();
    }

    var stderr = result.stderr as String;
    // Tidy up the compiler output to leave just the failure.
    stderr =
        stderr.replaceAll('Bad state: Generating kernel failed!', '').trim();
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
