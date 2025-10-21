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

    test('a.2 is built', () async {
      expect(await tester.build(), Result(written: ['a.2']));
    });

    group('with run_only_if_triggered, without triggers', () {
      setUp(() {
        tester.buildYaml(r'''
targets:
  $default:
    builders:
      invalidation_tester_builder:invalidation_tester_builder:
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

    group('with run_only_if_triggered, with trigger', () {
      setUp(() {
        tester.buildYaml(r'''
targets:
  $default:
    builders:
      invalidation_tester_builder:invalidation_tester_builder:
        options:
          run_only_if_triggered: true

triggers:
  invalidation_tester_builder:invalidation_tester_builder:
    - import trigger/trigger.dart
''');
        tester.importGraph({
          'a.1': ['package:trigger/trigger'],
        });
      });

      test('a.2 is built', () async {
        expect(await tester.build(), Result(written: ['a.2']));
      });

      test('a.2 is rebuilt on primary input change', () async {
        await tester.build();
        // TODO(davidmorgan): the primary input is currently counted as an input
        // due to the directive check. It would be possible to optimize to only
        // count "whether any directive matches" as an input, then this change
        // would not trigger a rebuild.
        expect(await tester.build(change: 'a.1'), Result(written: ['a.2']));
      });

      test('a.2 is rebuilt on input change', () async {
        await tester.build();
        expect(await tester.build(change: 'z'), Result(written: ['a.2']));
      });
    });

    group('with run_only_if_triggered, changes to triggers', () {
      test('a.2 is not built', () async {
        tester.buildYaml(r'''
targets:
  $default:
    builders:
      invalidation_tester_builder:invalidation_tester_builder:
        options:
          run_only_if_triggered: true

triggers:
  invalidation_tester_builder:invalidation_tester_builder:
    - import trigger/trigger.dart
''');
        expect(await tester.build(), Result(written: []));
      });

      test('a.2 is built when triggering direct import is added', () async {
        tester.buildYaml(r'''
targets:
  $default:
    builders:
      invalidation_tester_builder:invalidation_tester_builder:
        options:
          run_only_if_triggered: true

triggers:
  invalidation_tester_builder:invalidation_tester_builder:
    - import trigger/trigger.dart
''');
        await tester.build();
        tester.importGraph({
          'a.1': ['package:trigger/trigger'],
        });
        expect(await tester.build(change: 'a.1'), Result(written: ['a.2']));
      });

      test('a.2 is built when trigger is added for existing '
          'direct import', () async {
        tester.buildYaml(r'''
targets:
  $default:
    builders:
      invalidation_tester_builder:invalidation_tester_builder:
        options:
          run_only_if_triggered: true
''');
        tester.importGraph({
          'a.1': ['package:trigger/trigger'],
        });
        await tester.build();
        expect(
          await tester.build(
            buildYaml: r'''
targets:
  $default:
    builders:
      invalidation_tester_builder:invalidation_tester_builder:
        options:
          run_only_if_triggered: true

triggers:
  invalidation_tester_builder:invalidation_tester_builder:
    - import trigger/trigger.dart
''',
          ),
          Result(written: ['a.2']),
        );
      });

      test('a.2 is removed when run_only_if_triggered is set '
          'and no trigger', () async {
        tester.buildYaml(r'''
targets:
  $default:
    builders:
      invalidation_tester_builder:invalidation_tester_builder:
        options:
          run_only_if_triggered: false
''');
        expect(await tester.build(), Result(written: ['a.2']));
        expect(
          await tester.build(
            buildYaml: r'''
targets:
  $default:
    builders:
      invalidation_tester_builder:invalidation_tester_builder:
        options:
          run_only_if_triggered: true
''',
          ),
          Result(deleted: ['a.2']),
        );
      });

      test('a.2 is built when run_only_if_triggered is unset '
          'and no trigger', () async {
        tester.buildYaml(r'''
targets:
  $default:
    builders:
      invalidation_tester_builder:invalidation_tester_builder:
        options:
          run_only_if_triggered: true

triggers:
  invalidation_tester_builder:invalidation_tester_builder:
    - import trigger/trigger.dart
''');
        expect(await tester.build(), Result(written: []));
        expect(
          await tester.build(
            buildYaml: r'''
targets:
  $default:
    builders:
      invalidation_tester_builder:invalidation_tester_builder:
        options:
          run_only_if_triggered: false
''',
          ),
          Result(written: ['a.2']),
        );
      });

      test('a.2 is deleted when triggering direct import is removed', () async {
        tester.buildYaml(r'''
targets:
  $default:
    builders:
      invalidation_tester_builder:invalidation_tester_builder:
        options:
          run_only_if_triggered: true

triggers:
  invalidation_tester_builder:invalidation_tester_builder:
    - import trigger/trigger.dart
''');
        tester.importGraph({
          'a.1': ['package:trigger/trigger'],
        });
        await tester.build();
        tester.importGraph({'a.1': []});
        expect(await tester.build(change: 'a.1'), Result(deleted: ['a.2']));
      });

      test('a.2 is deleted when trigger is removed for '
          'existing import', () async {
        tester.buildYaml(r'''
targets:
  $default:
    builders:
      invalidation_tester_builder:invalidation_tester_builder:
        options:
          run_only_if_triggered: true

triggers:
  invalidation_tester_builder:invalidation_tester_builder:
    - import trigger/trigger.dart
''');
        tester.importGraph({
          'a.1': ['package:trigger/trigger'],
        });
        await tester.build();
        expect(
          await tester.build(
            buildYaml: r'''
targets:
  $default:
    builders:
      invalidation_tester_builder:invalidation_tester_builder:
        options:
          run_only_if_triggered: true
''',
          ),
          Result(deleted: ['a.2']),
        );
      });
    });
  });
}
