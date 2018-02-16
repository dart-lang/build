// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')

import 'package:io/io.dart';
import 'package:test/test.dart';

import 'common/utils.dart';

void main() {
  test('Can run passing tests with --precompiled', () async {
    await expectTestsPass(usePrecompiled: true);
  });

  test('Failing tests print mapped stack traces', () async {
    var result = await runAutoTests(
        testArgs: ['--run-skipped', 'test/hello_world_test.dart']);
    expect(result.exitCode, isNot(ExitCode.success));
    expect(result.stdout,
        matches(new RegExp(r'hello_world_test.dart [\d]+:[\d]+')));
    expect(result.stdout, isNot(contains('.js')));
  });
}
