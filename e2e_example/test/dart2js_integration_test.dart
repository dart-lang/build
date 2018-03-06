// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
@Timeout(const Duration(minutes: 5))
import 'dart:async';
import 'dart:io';

import 'package:test/test.dart';

import 'common/utils.dart';

void main() {
  group('Can run tests using dart2js', () {
    test('via build.yaml config flag', () async {
      await expectTestsPass(
          usePrecompiled: true,
          useManualScript: false,
          args: ['--config=dart2js']);
      await expectWasCompiledWithDart2Js(minified: false);
    }, onPlatform: {'windows': const Skip('flaky on windows')});

    test('via --define flag', () async {
      await expectTestsPass(
          usePrecompiled: true,
          useManualScript: false,
          args: [
            '--define',
            'build_web_compilers|entrypoint=compiler=dart2js',
            '--define',
            'build_web_compilers|entrypoint=dart2js_args=["--minify","--checked"]',
          ]);
      await expectWasCompiledWithDart2Js(minified: true);
    }, onPlatform: {'windows': const Skip('flaky on windows')});

    test('--define overrides --config', () async {
      await expectTestsPass(
          usePrecompiled: true,
          useManualScript: false,
          args: [
            '--config',
            'dart2js',
            '--define',
            'build_web_compilers|entrypoint=compiler=dart2js',
            '--define',
            'build_web_compilers|entrypoint=dart2js_args=["--minify","--checked"]',
          ]);
      await expectWasCompiledWithDart2Js(minified: true);
    }, onPlatform: {'windows': const Skip('flaky on windows')});
  });
}

Future<Null> expectWasCompiledWithDart2Js({bool minified: false}) async {
  var jsFile =
      new File('.dart_tool/build/generated/e2e_example/web/main.dart.js');
  expect(await jsFile.exists(), isTrue);
  // sanity check that it was indeed compiled with dart2js
  var content = await jsFile.readAsString();
  expect(content, contains('function generateAccessor('));
  if (minified) {
    expect(content, isNot(startsWith('//')));
  } else {
    expect(content, startsWith('//'));
  }
}
