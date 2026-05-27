// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Tags(['integration3'])
library;

import 'package:io/io.dart';
import 'package:test/test.dart';

import '../common/common.dart';

void main() async {
  test('test command', () async {
    final pubspecs = await Pubspecs.load();
    final tester = BuildRunnerTester(pubspecs);

    tester.writePackage(
      name: 'root_pkg',
      dependencies: ['build_runner'],
      files: {},
    );

    // `test` does not support specifying directory to build.
    var output = await tester.run(
      'root_pkg',
      'dart run build_runner test --force-jit web',
      expectExitCode: ExitCode.usage.code,
    );
    expect(
      output,
      contains(
        'The `test` command requires a `--` separator '
        'before any test arguments.',
      ),
    );

    output = await tester.run(
      'root_pkg',
      'dart run build_runner test --force-jit web -- -p chrome',
      expectExitCode: ExitCode.usage.code,
    );
    expect(
      output,
      contains(
        'The `test` command requires a `--` separator '
        'before any test arguments.',
      ),
    );

    // Corrected command instead fails with config error because `build_test`
    // dependency is missing.
    output = await tester.run(
      'root_pkg',
      'dart run build_runner test --force-jit -- web',
      expectExitCode: ExitCode.config.code,
    );
    expect(
      output,
      contains(
        'Missing dev dependency on package:build_test, '
        'which is required to run tests.',
      ),
    );

    // Add the `build_test` dependency, the argument is passed to `test` as
    // expected.
    tester.writePackage(
      name: 'root_pkg',
      dependencies: ['build_runner', 'build_test'],
      files: {
        'test/passes_fails_test.dart': '''
import 'package:test/test.dart';
void main() {
  test('passes', () {});
  test('fails', () {
    fail('should not run');
  });
}
''',
      },
    );

    // Succeds because only 'passes' runs.
    await tester.run('root_pkg', 'dart run build_runner test -- -n passes');
  });
}
