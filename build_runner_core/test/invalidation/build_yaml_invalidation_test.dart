// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import 'invalidation_tester.dart';

/// Invalidation tests in which the inputs are individually read arbitrary
/// assets.

void main() {
  late InvalidationTester tester;

  setUp(() {
    tester = InvalidationTester();
  });

  group('a+(z) <-- a.1', () {
    setUp(() {
      tester.sources(['a', 'z']);
      tester.builder(from: '', to: '.1')
        ..readsOther('z')
        ..writes('.1');
    });

    test('a.1 is built', () async {
      expect(await tester.build(), Result(written: ['a.1', 'z.1']));
    });

    test('a.1 is not built if not triggered', () async {
      tester.buildYaml(r'''
targets:
  $default:
    builders:
      TestBuilder:
        options:
          run_only_if_triggered: true
''');
      await tester.build();
      // TODO(davidmorgan): this should not update.
      expect(await tester.build(change: 'z'), Result(written: ['a.1', 'z.1']));
    });
  });
}
