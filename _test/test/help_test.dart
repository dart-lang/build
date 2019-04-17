// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
import 'dart:async';
import 'dart:io';

import 'package:test/test.dart';

import 'common/utils.dart';

void main() {
  test('pub run build_runner help', () async {
    await _testHelpCommand(() => runCommand(['help']));
  });

  test('pub run build_runner --help', () async {
    await _testHelpCommand(() => runCommand(['--help']));
  });

  test('pub run build_runner build --help', () async {
    await _testHelpCommand(() => runCommand(['build', '--help']));
  });

  test('pub run build_runner serve --help', () async {
    await _testHelpCommand(() => runCommand(['serve', '--help']));
  });

  test('pub run build_runner test --help', () async {
    await _testHelpCommand(() => runCommand(['test', '--help']));
  });

  test('pub run build_runner watch --help', () async {
    await _testHelpCommand(() => runCommand(['watch', '--help']));
  });
}

Future<void> _testHelpCommand(Future<ProcessResult> runCommand()) async {
  var asyncResult = runCommand();
  expect(asyncResult, completes,
      reason: 'should not cause the auto build script to hang');
  var result = await asyncResult;
  expect(result.exitCode, equals(0),
      reason: 'should give a successful exit code');
  expect(result.stderr, isEmpty, reason: 'Should output nothing on stderr');
  expect(result.stdout, isNot(contains('"Unhandled exception"')),
      reason: 'Should not print an unhandled exception');
}
