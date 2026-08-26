// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Tags(['integration2'])
library;

import 'package:test/test.dart';

import '../common/common.dart';

void main() async {
  test('end to end test for reflectable_test codegen', () async {
    final pubspecs = await Pubspecs.load();
    final tester = BuildRunnerTester(pubspecs);

    tester.copyPackage('reflectable_test_annotation');
    tester.copyPackage('reflectable_test_builder');

    tester.writePackage(
      name: 'test_pkg',
      dependencies: ['build_runner', 'test'],
      pathDependencies: [
        'reflectable_test_annotation',
        'reflectable_test_builder',
      ],
      files: {
        'test/my_test.dart': '''
import 'package:reflectable_test_annotation/reflectable_test_annotation.dart';
import 'package:test/test.dart' as test_package;

part 'my_test.rt.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MyTest_reflectiveTest);
  });
}

class BaseTest {
  void test_inherited() {
    test_package.expect(2 + 2, 4);
  }
}

@reflectiveTest
class MyTest extends BaseTest {
  void test_local() {
    test_package.expect(1 + 1, 2);
  }

  @skippedTest
  void test_skipped() {
    test_package.fail('should be skipped');
  }
}
''',
      },
    );

    final output = await tester.run(
      'test_pkg',
      'dart run build_runner build --separate-builder-compile',
    );
    expect(output, contains('wrote 1 output'));

    final testOutput = await tester.run('test_pkg', 'dart test');
    expect(testOutput, contains('All tests passed!'));
  });
}
