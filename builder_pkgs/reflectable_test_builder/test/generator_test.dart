// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:reflectable_test_builder/reflectable_test_builder.dart';
import 'package:test/test.dart';

void main() {
  test('generates reflective test descriptor with inheritance', () async {
    await testBuilder(
      reflectableTestBuilder(BuilderOptions.empty),
      {
        'reflectable_test_annotation|lib/reflectable_test_annotation.dart': '''
class ReflectiveTest {
  const ReflectiveTest();
}
const reflectiveTest = ReflectiveTest();

class SkippedTest {
  final String? reason;
  const SkippedTest([this.reason]);
}
const skippedTest = SkippedTest();
''',
        'a|lib/test.dart': '''
import 'package:reflectable_test_annotation/reflectable_test_annotation.dart';

part 'test.rt.dart';

class BaseTest {
  void test_inherited() {}
}

@reflectiveTest
class MyTest extends BaseTest {
  void test_local() {}

  @skippedTest
  void test_skipped() {}
}
''',
      },
      outputs: {
        'a|lib/test.rt.dart': decodedMatches(
          allOf([
            contains('final MyTest_reflectiveTest = _create_MyTest();'),
            contains("name: 'test_inherited'"),
            contains("name: 'test_local'"),
            contains("name: 'test_skipped'"),
            contains('isSkipped: true'),
          ]),
        ),
      },
    );
  });
}
