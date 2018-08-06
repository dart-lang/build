// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')

import 'package:io/io.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'common/utils.dart';

void main() {
  test('Can run passing tests with --precompiled', () async {
    await expectTestsPass(usePrecompiled: true);
  });

  test('Failing tests print mapped stack traces', () async {
    var result = await runTests(
        testArgs: ['--run-skipped', 'test/hello_world_test.dart']);
    printOnFailure(result.stderr.toString());
    expect(result.exitCode, isNot(ExitCode.success));
    expect(
        result.stdout, matches(RegExp(r'hello_world_test.dart [\d]+:[\d]+')));
    expect(result.stdout, isNot(contains('.js')));
  });

  group('file edits', () {
    setUp(() async {
      ensureCleanGitClient();
    });

    test('edit test to fail and rerun', () async {
      await replaceAllInFile(
          'test/common/message.dart', 'Hello World!', 'Goodbye World!');
      await expectTestsFail();
    });

    test('edit dependency lib causing test to fail and rerun', () async {
      await replaceAllInFile('lib/app.dart', 'Hello World!', 'Goodbye World!');
      await expectTestsFail();
    });

    test('create new test', () async {
      await createFile(p.join('test', 'other_test.dart'), basicTestContents);
      await expectTestsPass(expectedNumRan: 5);
    });

    test('delete test', () async {
      await deleteFile(p.join('test', 'sub-dir', 'subdir_test.dart'));
      await expectTestsPass(expectedNumRan: 3);
    });
  });
}

final basicTestContents = '''
import 'package:test/test.dart';

main() {
  test('1 == 1', () {
    expect(1, equals(1));
  });
}''';
