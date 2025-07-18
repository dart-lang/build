// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import 'invalidation_tester.dart';

void main() {
  late InvalidationTester tester;

  setUp(() {
    tester = InvalidationTester();
  });

  group('a.1+(z) <-- a.2', () {
    setUp(() {
      tester.sources(['a.1', 'z']);
      tester.builder(from: '.1', to: '.2')
        ..readsOther('z')
        ..writes('.2');
    });

    group('run only if triggered, without triggers', () {
      setUp(() {
        tester.buildYaml(r'''
targets:
  $default:
    builders:
      pkg:invalidation_tester_builder:
        options:
          run_only_if_triggered: true
''');
      });

      test('a.2 is not built', () async {
        expect(await tester.build(), Result(written: []));
      });

      test('a.2 is not built on primary input change', () async {
        expect(await tester.build(), Result(written: []));
        expect(await tester.build(change: 'a.1'), Result(written: []));
      });

      test('a.2 is not built on input change', () async {
        expect(await tester.build(), Result(written: []));
        expect(await tester.build(change: 'z'), Result(written: []));
      });
    });

    group('run only if triggered, with trigger', () {
      setUp(() {
        tester.buildYaml(r'''
targets:
  $default:
    builders:
      pkg:invalidation_tester_builder:
        options:
          run_only_if_triggered: true

triggers:
  pkg:invalidation_tester_builder:
    - import trigger/trigger.dart
''');
        tester.importGraph({
          'a.1': ['package:trigger/trigger.dart'],
        });
      });

      test('a.2 is built', () async {
        expect(await tester.build(), Result(written: ['a.2']));
      });

      test('a.2 is rebuilt on primary input change', () async {
        await tester.build();
        // TODO(davidmorgan): should not be rebuilt?
        expect(await tester.build(change: 'a.1'), Result(written: ['a.2']));
      });

      test('a.2 is rebuilt on input change', () async {
        await tester.build();
        expect(await tester.build(change: 'z'), Result(written: ['a.2']));
      });
    });
  });
}
