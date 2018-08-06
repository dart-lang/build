// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
@Timeout(const Duration(minutes: 5))
import 'dart:async';
import 'dart:io';

import 'package:test/test.dart';

import 'common/utils.dart';

const _outputDir = 'dart2js_test';

void main() {
  group('Can run tests using dart2js', () {
    tearDown(() async {
      var dir = Directory(_outputDir);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    });

    test('via build.yaml config flag', () async {
      await expectTestsPass(usePrecompiled: true, args: [
        '--config=dart2js',
        '--output=$_outputDir',
      ]);
      await expectWasCompiledWithDart2Js(minified: false);
    }, onPlatform: {'windows': const Skip('flaky on windows')});

    test('via --define flag', () async {
      await expectTestsPass(usePrecompiled: true, args: [
        '--define',
        'build_web_compilers|entrypoint=compiler=dart2js',
        '--define',
        'build_web_compilers|entrypoint=dart2js_args=["--minify","--checked"]',
        '--output=$_outputDir',
      ]);
      await expectWasCompiledWithDart2Js(minified: true);
    }, onPlatform: {'windows': const Skip('flaky on windows')});

    test('via --release mode', () async {
      await expectTestsPass(usePrecompiled: true, args: [
        '--release',
        '--output=$_outputDir',
      ]);
      await expectWasCompiledWithDart2Js(minified: true);
    }, onPlatform: {'windows': const Skip('flaky on windows')});

    test('--define overrides --config', () async {
      await expectTestsPass(usePrecompiled: true, args: [
        '--config',
        'dart2js',
        '--define',
        'build_web_compilers|entrypoint=compiler=dart2js',
        '--define',
        'build_web_compilers|entrypoint=dart2js_args=["--minify","--checked"]',
        '--output=$_outputDir',
      ]);
      await expectWasCompiledWithDart2Js(minified: true);
    }, onPlatform: {'windows': const Skip('flaky on windows')});
  });
}

Future<Null> expectWasCompiledWithDart2Js({bool minified = false}) async {
  var jsFile = File('$_outputDir/test/hello_world_deferred_test.dart.js');
  expect(await jsFile.exists(), isTrue);
  // sanity check that it was indeed compiled with dart2js
  var content = await jsFile.readAsString();
  expect(content, contains('function generateAccessor('));
  if (minified) {
    expect(content, isNot(startsWith('//')));
  } else {
    expect(content, startsWith('//'));
  }

  var jsDeferredPartFile =
      File('$_outputDir/test/hello_world_deferred_test.dart.js_1.part.js');
  expect(await jsDeferredPartFile.exists(), isTrue);
}
