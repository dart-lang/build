// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
@Timeout(const Duration(minutes: 5))
import 'dart:io';

import 'package:test/test.dart';

import 'common/utils.dart';

void main() {
  test('Can run tests using dart2js', () async {
    await expectTestsPass(
        usePrecompiled: true,
        useManualScript: false,
        args: ['--config=dart2js']);
    var jsFile =
        new File('.dart_tool/build/generated/e2e_example/web/main.dart.js');
    expect(await jsFile.exists(), isTrue);
    // sanity check that it was indeed compiled with dart2js
    expect(await jsFile.readAsString(), contains('dart2js'));
  }, onPlatform: {'windows': const Skip('flaky on windows')});
}
