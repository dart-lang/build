// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
import 'dart:async';

import 'package:test/test.dart';

import 'common/utils.dart';

void main() {
  test('pub run build_runner help', () async {
    await _testHelpCommand(['help'],
        checkContent: 'Unified interface for running Dart builds.');
    await _testHelpCommand(['--help'],
        checkContent: 'Unified interface for running Dart builds.');
  });

  test('pub run build_runner build --help', () async {
    await _testHelpCommand(['build', '--help'],
        checkContent: 'Performs a single build on the specified targets');
    await _testHelpCommand(['help', 'build'],
        checkContent: 'Performs a single build on the specified targets');
  });

  test('pub run build_runner serve --help', () async {
    await _testHelpCommand(['serve', '--help'],
        checkContent: 'Runs a development server');
    await _testHelpCommand(['help', 'serve'],
        checkContent: 'Runs a development server');
  });

  test('pub run build_runner test --help', () async {
    await _testHelpCommand(['test', '--help'],
        checkContent: 'and then runs tests using');
    await _testHelpCommand(['help', 'test'],
        checkContent: 'and then runs tests using');
  });

  test('pub run build_runner watch --help', () async {
    await _testHelpCommand(['watch', '--help'],
        checkContent: 'watching the file system for updates');
    await _testHelpCommand(['help', 'watch'],
        checkContent: 'watching the file system for updates');
  });
}

Future<void> _testHelpCommand(List<String> args, {String checkContent}) async {
  var asyncResult = runCommand(args);
  expect(asyncResult, completes,
      reason: 'should not cause the auto build script to hang');
  var result = await asyncResult;
  expect(result.exitCode, equals(0),
      reason: 'should give a successful exit code');
  expect(result.stderr, isEmpty, reason: 'Should output nothing on stderr');
  expect(result.stdout, isNot(contains('"Unhandled exception"')),
      reason: 'Should not print an unhandled exception');
  if (checkContent != null) {
    expect(result.stdout, contains(checkContent));
  }
}
