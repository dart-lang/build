// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Tags(['integration5'])
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
    await tester.run(
      'root_pkg',
      'dart run build_runner test web',
      expectExitCode: ExitCode.usage.code,
    );
    await tester.run(
      'root_pkg',
      'dart run build_runner test web -- -p chrome',
      expectExitCode: ExitCode.usage.code,
    );

    // Requires `build_test` dependency.
    final output = await tester.run(
      'root_pkg',
      'dart run build_runner test',
      expectExitCode: ExitCode.config.code,
    );
    expect(
      output,
      contains(
        'Missing dev dependency on package:build_test, '
        'which is required to run tests.',
      ),
    );
  });
}
