// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:io/io.dart';
import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

import '../common/common.dart';

main() {
  setUpAll(() async {
    await d.dir('a', [
      await pubspec('a', currentIsolateDependencies: [
        'build',
        'build_config',
        'build_runner',
        'build_test',
      ]),
      d.dir('test', [
        d.file('hello_test.dart', '''
import 'package:test/test.dart';
main() {
  test('hello', () {});
}'''),
      ]),
    ]).create();

    await pubGet('a');
  });

  test('build does not accept trailing args', () async {
    var result =
        await runPub('a', 'run', args: ['build_runner', 'build', 'extra']);
    expect(result.exitCode, ExitCode.usage.code);
    expect(result.stdout, contains('Unrecognized arguments: [extra]'));
  });

  test('watch does not accept trailing args', () async {
    var result =
        await runPub('a', 'run', args: ['build_runner', 'watch', 'extra']);
    expect(result.exitCode, ExitCode.usage.code);
    expect(result.stdout, contains('Unrecognized arguments: [extra]'));
  });
}

var basicBuildContent = '''
import 'dart:io';
import 'package:build_runner/build_runner.dart';
import 'package:build_test/build_test.dart';

main(List<String> args) async {
  exitCode = await run(
      args, [applyToRoot(new TestBuilder())]);
}
''';
