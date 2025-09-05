// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
@Timeout.factor(2)
library;

import 'dart:io';

import 'package:build_runner/src/bootstrap/bootstrap.dart';
import 'package:build_runner/src/bootstrap/build_process_state.dart';
import 'package:build_runner/src/bootstrap/build_script_generate.dart';
import 'package:build_runner/src/constants.dart';
import 'package:test/test.dart';

// These tests write to the real `build_runner/.dart_tool/build/entrypoint`
// but that's reasonably harmless as it can always contain invalid output
// due to version skew.
void main() {
  final scriptFile = File(scriptLocation);
  final kernelFile = File(scriptKernelLocation);

  setUp(() {
    if (scriptFile.existsSync()) scriptFile.deleteSync();
    if (kernelFile.existsSync()) kernelFile.deleteSync();
  });

  group('generateAndRun', () {
    test('writes dill', () async {
      await generateAndRun(
        [],
        script: '''
import 'dart:isolate';
import 'package:build_runner/src/bootstrap/build_process_state.dart';

void main(_, [SendPort? sendPort]) async {
  await buildProcessState.receive(sendPort);
  buildProcessState.send(sendPort);
}
''',
      );
      expect(kernelFile.existsSync(), true);
    });

    test('sends and receives buildProcessState', () async {
      final script = '''
import 'dart:isolate';
import 'package:build_runner/src/bootstrap/build_process_state.dart';

void main(_, [SendPort? sendPort]) async {
  await buildProcessState.receive(sendPort);
  buildProcessState.isolateExitCode = buildProcessState.isolateExitCode! + 1;
  buildProcessState.send(sendPort);
}
''';

      buildProcessState.isolateExitCode = 6;
      await generateAndRun([], script: script);
      expect(buildProcessState.isolateExitCode, 7);
      await generateAndRun([], script: script);
      expect(buildProcessState.isolateExitCode, 8);
    });

    test('rewrites dill if script changed', () async {
      expect(
        await generateAndRun(
          [],
          script: '''
import 'dart:isolate';
import 'package:build_runner/src/bootstrap/build_process_state.dart';

void main(_, [SendPort? sendPort]) async {
  await buildProcessState.receive(sendPort);
  buildProcessState.isolateExitCode = 3;
  buildProcessState.send(sendPort);
}
''',
        ),
        3,
      );
      expect(kernelFile.existsSync(), true);

      expect(
        await generateAndRun(
          [],
          script: '''
import 'dart:isolate';
import 'package:build_runner/src/bootstrap/build_process_state.dart';

void main(_, [SendPort? sendPort]) async {
  await buildProcessState.receive(sendPort);
  buildProcessState.isolateExitCode = 4;
  buildProcessState.send(sendPort);
}
''',
        ),
        4,
      );
    });

    test(
      'rewrites dill if there is an asset graph and script changed',
      () async {
        File(
          assetGraphPathFor(scriptKernelLocation),
        ).createSync(recursive: true);
        expect(
          await generateAndRun(
            [],
            script: '''
import 'dart:isolate';
import 'package:build_runner/src/bootstrap/build_process_state.dart';

void main(_, [SendPort? sendPort]) async {
  await buildProcessState.receive(sendPort);
  buildProcessState.isolateExitCode = 3;
  buildProcessState.send(sendPort);
}
''',
          ),
          3,
        );
        expect(kernelFile.existsSync(), true);
        expect(
          File(assetGraphPathFor(scriptKernelLocation)).existsSync(),
          true,
        );

        expect(
          await generateAndRun(
            [],
            script: '''
import 'dart:isolate';
import 'package:build_runner/src/bootstrap/build_process_state.dart';

void main(_, [SendPort? sendPort]) async {
  await buildProcessState.receive(sendPort);
  buildProcessState.isolateExitCode = 4;
  buildProcessState.send(sendPort);
}
''',
          ),
          4,
        );
      },
    );
  });
}
