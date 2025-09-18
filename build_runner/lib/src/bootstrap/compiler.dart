// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import '../logging/build_log.dart';

class CompileResult {
  final String? messages;

  CompileResult({required this.messages});

  bool get succeeded => messages == null;
}

// TODO(davidmorgan): experiments.
class Compiler {
  Future<CompileResult> compile({Iterable<String>? experiments}) async {
    buildLog.debug('compile with $experiments');
    buildLog.doing('Compiling the build script.');
    final result = await Process.run('dart', [
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

    var stderr = result.stderr as String;
    stderr =
        stderr.replaceAll('Bad state: Generating kernel failed!', '').trim();
    return CompileResult(messages: result.exitCode == 0 ? null : stderr);
  }
}
