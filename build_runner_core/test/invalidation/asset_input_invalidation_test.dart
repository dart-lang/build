// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import 'invalidation_tester.dart';

/// Invalidation tests in which the inputs are individually read arbitrary
/// assets.
///
/// In the test names:
///
///  - `a1 <-- a2` means a1 is the primary input of a2, but _not_ an input:
///    the builder does not read a1
///  - `a1 <== a2` means a1 is the primary input of a2 _and_ is an input:
///    the builder _does_ read a1
///  - `[a1]` means a1 is an optional output
///  - `a1+(z1+z2) <-- a2` means z1 and z2 are non-primary inputs of a2

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

  // The same as the previous group, but a.2 is now an optional output.
  group('a.1 <== [a.2], b.3+(a.2) <== b.4', () {
    setUp(() {
      tester.sources(['a.1', 'b.3']);
      tester.builder(from: '.1', to: '.2', isOptional: true)
        ..reads('.1')
        ..writes('.2');
      tester.builder(from: '.3', to: '.4')
        ..reads('.3')
        ..readsOther('a.2')
        ..writes('.4');
    });

    test('b.4 is built', () async {
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

  // As previous group but with b.4 now optional and introducing c.6 that
  // depends on it.
  group('a.1 <== [a.2], b.3+(a.2) <== [b.4], c.5+(b.4) <== c.6', () {
    setUp(() {
      tester.sources(['a.1', 'b.3', 'c.5']);
      tester.builder(from: '.1', to: '.2', isOptional: true)
        ..reads('.1')
        ..writes('.2');
      tester.builder(from: '.3', to: '.4', isOptional: true)
        ..reads('.3')
        ..readsOther('a.2')
        ..writes('.4');
      tester.builder(from: '.5', to: '.6')
        ..reads('.5')
        ..readsOther('b.4')
        ..writes('.6');
    });

    test('c.6 is built', () async {
      expect(await tester.build(), Result(written: ['a.2', 'b.4', 'c.6']));
    });

    test('change a.1, a.2+b.4+c.6 are rebuilt', () async {
      await tester.build();
      expect(
        await tester.build(change: 'a.1'),
        Result(written: ['a.2', 'b.4', 'c.6']),
      );
    });

    test('delete a.1, a.2 is deleted and b.4+c.6 are rebuilt', () async {
      await tester.build();
      expect(
        await tester.build(delete: 'a.1'),
        Result(deleted: ['a.2'], written: ['b.4', 'c.6']),
      );
    });

    test('create a.1, a.2+b.4+c.6 are rebuilt', () async {
      tester.sources(['b.3', 'c.5']);
      await tester.build();
      expect(
        await tester.build(create: 'a.1'),
        Result(written: ['a.2', 'b.4', 'c.6']),
      );
    });
  });

  // Builder input set grows between builds.
  group('a.1 <== [a.2], b.3 <== b.4', () {
    late TestBuilderBuilder bBuilder;

    setUp(() {
      tester.sources(['a.1', 'b.3']);
      tester.builder(from: '.1', to: '.2', isOptional: true)
        ..reads('.1')
        ..writes('.2');
      bBuilder =
          tester.builder(from: '.3', to: '.4')
            ..reads('.3')
            ..writes('.4');
    });

    test('only b.4 is built', () async {
      expect(await tester.build(), Result(written: ['b.4']));
    });

    test('changes to b.3+(a.2) <== b.4, a.2 is built', () async {
      expect(await tester.build(), Result(written: ['b.4']));

      // Builder for 'b.4' reads additional input 'a.2' in the next build.
      //
      // Normally a builder's inputs can only change if the contents of its
      // inputs change to trigger additional reads. Simulate this by telling the
      // builder to read 'a.2' on the next run then changing its input so it
      // will rerun.
      bBuilder.readsOther('a.2');

      // Now the optional 'a.2' is needed so it's built, and 'b.4' is rebuilt.
      expect(
        await tester.build(change: 'b.3'),
        Result(written: ['a.2', 'b.4']),
      );
    });
  });
}
