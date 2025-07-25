// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'bootstrap_action.dart';

void main(List<String> arguments) async {
  await Compiler().compile(arguments[0]);
}

BootstrapAction compileToKernelBootstrapAction() => BootstrapAction(
  outputPath: '.dart_tool/build/entrypoint/build.dart',
  action: () => Compiler().compile('.dart_tool/build/entrypoint/build.dart'),
);

class Compiler {
  Future<BootstrapActionResult> compile(String path) async {
    final result = await Process.run('dart', [
      'compile',
      'kernel',
      path,
      '--depfile',
      '$path.deps',
    ]);
    if (result.exitCode != 0) {
      print('Compile failed: ${result.stdout} ${result.stderr}');
      return BootstrapActionResult(
        ran: true,
        succeeded: false,
        messages: result.stderr as String,
      );
    }

    return BootstrapActionResult(ran: true, succeeded: true);
  }
}
