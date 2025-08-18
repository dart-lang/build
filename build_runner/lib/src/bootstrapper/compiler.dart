// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:build_runner_core/build_runner_core.dart';

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
    if (result.exitCode != 0) {
      print('Compile failed: ${result.stdout} ${result.stderr}');
      return CompileResult(messages: result.stderr as String);
    }
    return CompileResult(messages: null);
  }
}
