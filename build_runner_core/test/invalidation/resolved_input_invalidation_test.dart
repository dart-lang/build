// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import 'invalidation_tester.dart';

/// In the test names:
///
/// - `a1 <== a2` means a1 is the primary input of a2 _and_ is an input:
///    the builder _does_ read a1
/// -  dart source import graphs are introduced with "resolves", so
///    `a1 resolves: a2 --> a3 --> a4` means that the generation of a1
///    resolves a2, which imports a3, which imports a4
void main() {
  late InvalidationTester tester;

  setUp(() {
    tester = InvalidationTester();
  });

  group('a.1 <== a.2, a.2 resolves: a.1 --> za --> zb', () {
    setUp(() {
      tester.sources(['a.1', 'za', 'zb']);
      tester.importGraph({
        'a.1': ['za'],
        'za': ['zb'],
      });
      tester.builder(from: '.1', to: '.2')
        ..reads('.1')
        ..resolvesOther('a.1')
        ..writes('.2');
    });

    test('a.2 is built', () async {
      expect(await tester.build(), Result(written: ['a.2']));
    });

    test('change za, a.2 is rebuilt', () async {
      await tester.build();
      expect(await tester.build(change: 'za'), Result(written: ['a.2']));
    });

    test('change zb, a.2 is rebuilt', () async {
      await tester.build();
      expect(await tester.build(change: 'zb'), Result(written: ['a.2']));
    });
  });

  // Transitive dependencies via files generated in earlier phases.
  group('a.1 <== a.2, a.3 <== a.4, a.5 <== a.6, '
      'a.6 resolves: z -> a.4 --> a.2', () {
    setUp(() {
      tester.sources(['a.1', 'a.3', 'a.5', 'z']);
      tester.importGraph({
        'z': ['a.4'],
        'a.4': ['a.2'],
      });
      tester.builder(from: '.1', to: '.2')
        ..reads('.1')
        ..writes('.2');
      tester.builder(from: '.3', to: '.4')
        ..reads('.3')
        ..writes('.4');
      tester.builder(from: '.5', to: '.6')
        ..reads('.5')
        ..resolvesOther('a.4')
        ..writes('.6');
    });

    test('a.6 is built', () async {
      expect(await tester.build(), Result(written: ['a.2', 'a.4', 'a.6']));
    });

    test('change a.1, a.6 is rebuilt', () async {
      expect(await tester.build(), Result(written: ['a.2', 'a.4', 'a.6']));
      expect(
        await tester.build(change: 'a.1'),
        Result(written: ['a.2', 'a.6']),
      );
    });
  });

  // As previous group, but with builders in reverse order so the transitive
  // import is not available and is not an input.
  group('a.5 <== a.6, a.3 <== a.4, a.1 <== a.2, a.6 resolves: z -> a.4', () {
    setUp(() {
      tester.sources(['a.1', 'a.3', 'a.5', 'z']);
      tester.importGraph({
        'z': ['a.4'],
        'a.4': ['a.2'],
      });
      tester.builder(from: '.5', to: '.6')
        ..reads('.5')
        ..resolvesOther('z')
        ..writes('.6');
      tester.builder(from: '.3', to: '.4')
        ..reads('.3')
        ..writes('.4');
      tester.builder(from: '.1', to: '.2')
        ..reads('.1')
        ..writes('.2');
    });

    test('a.6 is built', () async {
      expect(await tester.build(), Result(written: ['a.2', 'a.4', 'a.6']));
    });

    test('change a.1, a.6 is not rebuilt', () async {
      expect(await tester.build(), Result(written: ['a.2', 'a.4', 'a.6']));
      expect(await tester.build(change: 'a.1'), Result(written: ['a.2']));
    });
  });
}
