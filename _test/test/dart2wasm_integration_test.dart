// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
@Tags(['integration'])
library;

import 'dart:async';
import 'dart:io';

import 'package:test/test.dart';

import 'common/utils.dart';

const _outputDir = 'dart2wasm_test';

void main() {
  group('Can run tests using dart2wasm', () {
    tearDown(() async {
      var dir = Directory(_outputDir);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    });

    test('via build.yaml config flag', () async {
      await expectTestsPass(usePrecompiled: true, buildArgs: [
        '--config=dart2wasm',
        '--output=$_outputDir',
      ]);
      await _expectWasCompiledWithDart2Wasm();
    }, onPlatform: {'windows': const Skip('flaky on windows')});

    test('via --define flag', () async {
      await expectTestsPass(usePrecompiled: true, buildArgs: [
        '--define',
        'build_web_compilers:entrypoint=compiler=dart2wasm',
        '--define',
        'build_web_compilers:entrypoint=dart2wasm_args='
            '["--enable-asserts", "-E--enable-experimental-ffi"]',
        '--output=$_outputDir',
      ]);
      await _expectWasCompiledWithDart2Wasm();
    }, onPlatform: {'windows': const Skip('flaky on windows')});

    test('via --release mode', () async {
      await expectTestsPass(usePrecompiled: true, buildArgs: [
        '--release',
        '--config=dart2wasm',
        '--output=$_outputDir',
      ]);
      await _expectWasCompiledWithDart2Wasm();
    }, onPlatform: {'windows': const Skip('flaky on windows')});
  });
}

Future<void> _expectWasCompiledWithDart2Wasm() async {
  var wasmFile =
      File('$_outputDir/test/hello_world_deferred_test.dart.browser_test.wasm');
  expect(await wasmFile.exists(), isTrue,
      reason: '${wasmFile.path} should exist');
}
