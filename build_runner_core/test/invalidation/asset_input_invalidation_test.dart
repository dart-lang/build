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

    test('change z, a.1 is rebuilt', () async {
      await tester.build();
      expect(await tester.build(change: 'z'), Result(written: ['a.1', 'z.1']));
    });

    test('delete z, a.1 is rebuilt', () async {
      await tester.build();
      expect(
        await tester.build(delete: 'z'),
        Result(written: ['a.1'], deleted: ['z.1']),
      );
    });

    test('create z, a.1 is rebuilt', () async {
      tester.sources(['a']);
      expect(await tester.build(), Result(written: ['a.1']));
      expect(await tester.build(create: 'z'), Result(written: ['a.1', 'z.1']));
    });
  });

  group('a.1 <== a.2, b.3+(a.2) <== b.4', () {
    setUp(() {
      tester.sources(['a.1', 'b.3']);
      tester.builder(from: '.1', to: '.2')
        ..reads('.1')
        ..writes('.2');
      tester.builder(from: '.3', to: '.4')
        ..reads('.3')
        ..readsOther('a.2')
        ..writes('.4');
    });

    test('a.4 is built', () async {
      expect(await tester.build(), Result(written: ['a.2', 'b.4']));
    });

    test('change a.1, a.2+b.4 are rebuilt', () async {
      await tester.build();
      expect(
        await tester.build(change: 'a.1'),
        Result(written: ['a.2', 'b.4']),
      );
    });

    test('delete a.1, a.2 is deleted and b.4 is rebuilt', () async {
      await tester.build();
      expect(
        await tester.build(delete: 'a.1'),
        Result(deleted: ['a.2'], written: ['b.4']),
      );
    });

    test('create a.1, a.2+b.4 are rebuilt', () async {
      tester.sources(['b.3']);
      await tester.build();
      expect(
        await tester.build(create: 'a.1'),
        Result(written: ['a.2', 'b.4']),
      );
    });
  });
}
