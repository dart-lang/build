// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

import 'package:_test_common/common.dart';

void main() {
  setUp(() async {
    await d.dir('a', [
      await pubspec('a', currentIsolateDependencies: [
        'build',
        'build_config',
        'build_modules',
        'build_resolvers',
        'build_runner',
        'build_runner_core',
        'build_vm_compilers',
      ], versionDependencies: {
        'glob': 'any',
        'path': 'any',
      }),
      d.dir('bin', [
        d.file('hello.dart', '''
import 'package:path/path.dart' as p;

void main() {
  print(p.url.join('hello', 'world'));
}
'''),
      ]),
    ]).create();

    await pubGet('a');
  });

  test('can compile vm apps to kernel and run them', () async {
    // Run a build and expect it to succeed.
    var buildResult =
        await runPub('a', 'run', args: ['build_runner', 'build', '-o', 'out']);
    expect(buildResult.exitCode, 0, reason: buildResult.stderr as String);
    var runResult = await runDart('a', 'out/bin/hello.vm.app.dill');

    // Run the app and expect certain output.
    expect(runResult.exitCode, 0, reason: runResult.stderr as String);
    expect(runResult.stdout, 'hello/world\n');
  }, skip: 'Blocked on https://dart-review.googlesource.com/c/sdk/+/62120');
}
