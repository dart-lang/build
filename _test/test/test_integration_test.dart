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

  test('Can build and run a single test with --precompiled and --build-filter',
      () async {
    var buildArgs = ['--build-filter', 'test/hello_world_test.*.dart.js'];
    await expectTestsPass(
        usePrecompiled: true,
        testArgs: ['test/hello_world_test.dart'],
        buildArgs: buildArgs);

    // This wasn't built so it should fail
    await expectTestsFail(
        usePrecompiled: true,
        testArgs: ['test/hello_world_custom_html_test.dart'],
        buildArgs: buildArgs);
  });

  test('Failing tests print mapped stack traces', () async {
    var result = await runTests(
        testArgs: ['--run-skipped', 'test/hello_world_test.dart']);
    expect(result.stdout,
        emitsThrough(matches(RegExp(r'hello_world_test.dart [\d]+:[\d]+'))));
    expect(result.stdout, neverEmits(contains('.js')));
    expect(await result.exitCode, isNot(ExitCode.success));
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
      await expectTestsPass(expectedNumRan: 7);
    });

    test('delete test', () async {
      await deleteFile(p.join('test', 'sub-dir', 'subdir_test.dart'));
      await expectTestsPass(expectedNumRan: 5);
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
