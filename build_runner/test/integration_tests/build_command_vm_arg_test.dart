// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Tags(['integration3'])
library;

import 'package:test/test.dart';

import '../common/common.dart';

void main() {
  test('passing custom vm args to build script', () async {
    final pubspecs = await Pubspecs.load();
    final tester = BuildRunnerTester(pubspecs);

    tester.writePackage(
      name: 'root_pkg',
      dependencies: ['build_runner'],
      files: {},
    );

    // This should lauch the inner build script with dart run --help ..., so we
    // check that help output is emitted to verify that the option is respected.
    final output = await tester.run(
      'root_pkg',
      'dart run build_runner build --dart-jit-vm-arg=--help',
    );

    expect(output, contains('Run "dart help" to see global options.'));
  });
}
