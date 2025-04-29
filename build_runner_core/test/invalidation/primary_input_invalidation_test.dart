// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import 'invalidation_tester.dart';

/// Invalidation tests in which the only inputs are primary inputs.
///
/// In the test names:
///
///  - `a1 <-- a2` means a1 is the primary input of a2, but _not_ an input:
///    the builder does not read a1
///  - `a1 <== a2` means a1 is the primary input of a2 _and_ is an input:
///    the builder _does_ read a1
///  - `[a1]` means a1 is an optional output
void main() {
  late InvalidationTester tester;

  setUp(() {
    tester = InvalidationTester();
    tester.sources(['a']);
  });

  group('a <-- a.1', () {
    setUp(() {
      tester.builder(from: '', to: '.1').writes('.1');
    });

    test('a.1 is built', () async {
      expect(await tester.build(), Result(written: ['a.1']));
    });

    test('a.1 can be output by failing generator', () async {
      tester.fail('a.1');
      expect(await tester.build(), Result.failure(written: ['a.1']));
    });

    test('change a, nothing is rebuilt', () async {
      await tester.build();
      expect(await tester.build(change: 'a'), Result());
    });

    test('delete a, a.1 is deleted', () async {
      await tester.build();
      expect(await tester.build(delete: 'a'), Result(deleted: ['a.1']));
    });

    test('delete a.1, a.1 is rebuilt', () async {
      await tester.build();
      expect(await tester.build(delete: 'a.1'), Result(written: ['a.1']));
    });

    test('create b, b.1 is built', () async {
      await tester.build();
      expect(await tester.build(create: 'b'), Result(written: ['b.1']));
    });
  });

  group('a <== a.1', () {
    setUp(() {
      tester.builder(from: '', to: '.1')
        ..reads('')
        ..writes('.1');
    });

    test('change a, a.1 is rebuilt', () async {
      await tester.build();
      expect(await tester.build(change: 'a'), Result(written: ['a.1']));
    });
  });

  group('a <-- [a.1]', () {
    setUp(() {
      tester.builder(from: '', to: '.1', isOptional: true).writes('.1');
    });

    test('a.1 is not built', () async {
      expect(await tester.build(), Result());
    });

    test('change a, a.1 is not built', () async {
      await tester.build();
      expect(await tester.build(change: 'a'), Result());
    });

    test('change a, failed a.1 is not built', () async {
      // "a" is not an input of "a.1", so changing "a" does not retry the
      // failed "a.1" build: it would fail exactly the same.
      tester
        ..fail('a.1')
        ..skipOutput('a.1');
      await tester.build();
      tester
        ..succeed('a.1')
        ..digestOutput('a.1');
      expect(await tester.build(change: 'a'), Result());
    });
  });

  group('a <-- a.1 <-- a.2', () {
    setUp(() {
      tester.builder(from: '', to: '.1').writes('.1');
      tester.builder(from: '.1', to: '.2').writes('.2');
    });

    test('a.1 is not output, a.2 is not built', () async {
      tester.skipOutput('a.1');
      expect(await tester.build(), Result());
    });

    test('a.1 is output but fails, a.2 is not built', () async {
      tester
        ..fail('a.1')
        ..skipOutput('a.1');

      expect(await tester.build(), Result.failure());
    });

    test('a.1+a.2 are built', () async {
      expect(await tester.build(), Result(written: ['a.1', 'a.2']));
    });

    test('change a, no rebuilds', () async {
      await tester.build();
      expect(await tester.build(change: 'a'), Result());
    });

    test('delete a, a.1+a.2 are deleted', () async {
      await tester.build();
      expect(await tester.build(delete: 'a'), Result(deleted: ['a.1', 'a.2']));
    });

    test('delete a.1, a.1 is rebuilt', () async {
      await tester.build();
      expect(await tester.build(delete: 'a.1'), Result(written: ['a.1']));
    });

    test('delete a.2, a.2 is rebuilt', () async {
      await tester.build();
      expect(await tester.build(delete: 'a.2'), Result(written: ['a.2']));
    });
  });

  group('a <== a.1 <-- a.2', () {
    setUp(() {
      tester.builder(from: '', to: '.1')
        ..reads('')
        ..writes('.1');
      tester.builder(from: '.1', to: '.2').writes('.2');
    });

    test('change a, a.1 is rebuilt', () async {
      await tester.build();
      expect(await tester.build(change: 'a'), Result(written: ['a.1']));
    });

    test('a.1 is built after fix, a.2 is built', () async {
      tester
        ..fail('a.1')
        ..skipOutput('a.1');
      expect(await tester.build(), Result.failure());
      tester
        ..succeed('a.1')
        ..digestOutput('a.1');
      expect(await tester.build(change: 'a'), Result(written: ['a.1', 'a.2']));
    });

    test('change a, on rebuild a.1 is not output, a.2 is deleted', () async {
      expect(await tester.build(), Result(written: ['a.1', 'a.2']));
      tester.skipOutput('a.1');
      expect(
        await tester.build(change: 'a'),
        // TODO(davidmorgan): this would be the correct result, see
        // https://github.com/dart-lang/build/issues/3875.
        // Result(deleted: ['a.1', 'a.2']),
        Result(deleted: ['a.1']),
      );
    });
  });

  group('a <-- a.1 <== a.2', () {
    setUp(() {
      tester.builder(from: '', to: '.1').writes('.1');
      tester.builder(from: '.1', to: '.2')
        ..reads('.1')
        ..writes('.2');
    });

    test('change a, nothing is rebuilt', () async {
      await tester.build();
      expect(await tester.build(change: 'a'), Result());
    });
  });

  group('a <== a.1 <== a.2', () {
    setUp(() {
      tester.builder(from: '', to: '.1')
        ..reads('')
        ..writes('.1');
      tester.builder(from: '.1', to: '.2')
        ..reads('.1')
        ..writes('.2');
    });

    test('change a, a.1+a.2 are rebuilt', () async {
      await tester.build();
      expect(await tester.build(change: 'a'), Result(written: ['a.1', 'a.2']));
    });

    test(
      'change a, a.1 is rebuilt, produces same output so a.2 is not rebuilt',
      () async {
        tester.fixOutput('a.1');
        await tester.build();
        expect(await tester.build(change: 'a'), Result(written: ['a.1']));
      },
    );

    test('change a, on rebuild a.1 is not output, a.2 is deleted', () async {
      expect(await tester.build(), Result(written: ['a.1', 'a.2']));
      tester.skipOutput('a.1');
      expect(
        await tester.build(change: 'a'),
        // TODO(davidmorgan): this would be the correct result, see
        // https://github.com/dart-lang/build/issues/3875.
        // Result(deleted: ['a.1', 'a.2']),
        Result(deleted: ['a.1']),
      );
    });
  });

  group('a <-- [a.1] <-- a.2', () {
    setUp(() {
      tester.builder(from: '', to: '.1', isOptional: true).writes('.1');
      tester.builder(from: '.1', to: '.2').writes('.2');
    });

    test('a.1+a.2 are built', () async {
      expect(await tester.build(), Result(written: ['a.1', 'a.2']));
    });

    test('change a, no rebuilds', () async {
      await tester.build();
      expect(await tester.build(change: 'a'), Result());
    });

    test('delete a, a.1+a.2 are deleted', () async {
      await tester.build();
      expect(await tester.build(delete: 'a'), Result(deleted: ['a.1', 'a.2']));
    });

    test('delete a.1, a.1 is rebuilt', () async {
      await tester.build();
      expect(await tester.build(delete: 'a.1'), Result(written: ['a.1']));
    });

    test('delete a.2, a.2 is rebuilt', () async {
      await tester.build();
      expect(await tester.build(delete: 'a.2'), Result(written: ['a.2']));
    });
  });

  group('a <-- [a.1] <-- a.2 <-- [a.3]', () {
    setUp(() {
      tester.builder(from: '', to: '.1', isOptional: true).writes('.1');
      tester.builder(from: '.1', to: '.2').writes('.2');
      tester.builder(from: '.2', to: '.3', isOptional: true).writes('.3');
    });

    test('a.3 is not built', () async {
      expect(await tester.build(), Result(written: ['a.1', 'a.2']));
    });
  });

  group('a <-- [a.1] <-- a.2 <-- [a.3] <-- a.4', () {
    setUp(() {
      tester.builder(from: '', to: '.1', isOptional: true).writes('.1');
      tester.builder(from: '.1', to: '.2').writes('.2');
      tester.builder(from: '.2', to: '.3', isOptional: true).writes('.3');
      tester.builder(from: '.3', to: '.4').writes('.4');
    });

    test('a.1+a.2+a.3+a.4 are built', () async {
      expect(
        await tester.build(),
        Result(written: ['a.1', 'a.2', 'a.3', 'a.4']),
      );
    });

    test('change a, no rebuilds', () async {
      await tester.build();
      expect((await tester.build(change: 'a')).written, isEmpty);
    });

    test('create b, b.1+b.2+b.3+b.4 are built', () async {
      await tester.build();
      expect(
        await tester.build(create: 'b'),
        Result(written: ['b.1', 'b.2', 'b.3', 'b.4']),
      );
    });
  });

  group('a <== [a.1] <== a.2 <== [a.3] <== a.4', () {
    setUp(() {
      tester.builder(from: '', to: '.1', isOptional: true)
        ..reads('')
        ..writes('.1');
      tester.builder(from: '.1', to: '.2')
        ..reads('.1')
        ..writes('.2');
      tester.builder(from: '.2', to: '.3', isOptional: true)
        ..reads('.2')
        ..writes('.3');
      tester.builder(from: '.3', to: '.4')
        ..reads('.3')
        ..writes('.4');
    });

    test('change a, a.1+a.2+a.3+a.4 are rebuilt', () async {
      await tester.build();
      expect(
        await tester.build(change: 'a'),
        Result(written: ['a.1', 'a.2', 'a.3', 'a.4']),
      );
    });

    test('change a, a.1+a.2 are rebuilt, '
        'produces same output so a.3+a.4 are not rebuilt', () async {
      tester.fixOutput('a.2');
      await tester.build();
      expect(await tester.build(change: 'a'), Result(written: ['a.1', 'a.2']));
    });

    test(
      'change a to recover from failure, a.1+a.2+a.3+a.4 are built',
      () async {
        tester.fail('a.1');
        expect(await tester.build(), Result.failure(written: ['a.1']));
        tester.succeed('a.1');
        expect(
          await tester.build(change: 'a'),
          Result(written: ['a.1', 'a.2', 'a.3', 'a.4']),
        );
      },
    );

    test('change a, on rebuild a.2 is not output', () async {
      expect(
        await tester.build(),
        Result(written: ['a.1', 'a.2', 'a.3', 'a.4']),
      );
      tester.skipOutput('a.2');
      expect(
        await tester.build(change: 'a'),
        // TODO(davidmorgan): this would be the correct result, see
        // https://github.com/dart-lang/build/issues/3875.
        // Result(written: ['a.1'], deleted: ['a.2', 'a.3', 'a.4']),
        Result(written: ['a.1'], deleted: ['a.2']),
      );
    });
  });
}
