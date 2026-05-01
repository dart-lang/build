// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import '../common/common.dart';

void main() {
  test('build command other args', () async {
    final pubspecs = await Pubspecs.load();
    final tester = BuildRunnerTester(pubspecs);

    tester.writePackage(
      name: 'root_pkg',
      dependencies: ['build_runner'],
      files: {},
    );

    // Passing custom vm args to build script.
    // This should lauch the inner build script with dart run --help ..., so we
    // check that help output is emitted to verify that the option is respected.
    var output = await tester.run(
      'root_pkg',
      'dart run build_runner build --force-jit --dart-jit-vm-arg=--help',
    );

    expect(output, contains('Run "dart help" to see global options.'));

    // Warning for removed flags.
    output = await tester.run(
      'root_pkg',
      'dart run build_runner build --force-jit --fail-on-severe '
          '--low-resources-mode',
    );

    expect(
      output,
      contains(
        'W These options have been removed and were ignored: '
        '--fail-on-severe, --low-resources-mode',
      ),
    );
  });
}
