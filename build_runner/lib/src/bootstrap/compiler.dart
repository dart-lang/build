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
  Future<CompileResult> compile() async {
    buildLog.doing('Compiling the build script.');
    final result = await Process.run('dart', [
      'compile',
      'kernel',
      '.dart_tool/build/entrypoint/build.dart',
      '--output',
      '.dart_tool/build/entrypoint/build.dart.dill',
      '--depfile',
      '.dart_tool/build/entrypoint/build.dart.dill.deps',
    ]);
    return CompileResult(
      messages: result.exitCode == 0 ? null : result.stderr as String,
    );
  }
}
