// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Tags(['experiments'])
@TestOn('vm')
library;

import 'package:build_runner/build_script_generate.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

void main() {
  test('build scripts can use experiments', () async {
    final logger = Logger.detached('test')..level = Level.ALL;
    logger.onRecord.listen((r) => printOnFailure(r.message));
    final exitCode = await generateAndRun(
      [],
      experiments: ['records'],
      generateBuildScript: () async {
        return '''
              // @dart=3.0
              import 'dart:io';
              import 'dart:isolate';
              import 'package:build_runner/src/build_script_generate/build_process_state.dart';

              void main(List<String> _, SendPort sendPort) {
                buildProcessState.receive(sendPort);
                var x = (1, 2);
                buildProcessState.isolateExitCode = (x.\$2);
                buildProcessState.send(sendPort);
              }
              ''';
      },
      logger: logger,
    );
    expect(exitCode, 2);
  });
}
