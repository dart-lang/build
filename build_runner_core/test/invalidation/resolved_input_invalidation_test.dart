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
      tester.sources(['a.1', 'za', 'zb', 'zc']);
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

    test('the import graph can change between builds', () async {
      await tester.build();
      // Initially there is no import of 'zc', so changing it does nothing.
      expect(await tester.build(change: 'zc'), Result());
      // But changing 'zb' triggers rebuild.
      expect(await tester.build(change: 'zb'), Result(written: ['a.2']));

      // Switch the import from 'za' from 'zb' onto 'zc'.
      tester.importGraph({
        'a.1': ['za'],
        'za': ['zc'],
      });
      expect(await tester.build(change: 'za'), Result(written: ['a.2']));

      // Now changing 'zb' does nothing.
      expect(await tester.build(change: 'zb'), Result());
      // But changing 'zc' triggers rebuild.
      expect(await tester.build(change: 'zc'), Result(written: ['a.2']));
    });

    test(
      'parts of the import graph that are not recomputed are retained',
      () async {
        await tester.build();
        // The second build does not need to compute the import graph.
        expect(await tester.build(), Result());
        // But the third build needs the import graph. So, it needs to
        // have been retained from the first build.
        expect(await tester.build(change: 'zb'), Result(written: ['a.2']));
      },
    );

    test('missing import triggers build when it appears', () async {
      tester.sources(['a.1', 'za']);
      expect(await tester.build(), Result(written: ['a.2']));
      expect(await tester.build(create: 'zb'), Result(written: ['a.2']));
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

  // Various dependencies onto five node source dependency graph.
  group('a.1 <== a.2, a.2 resolves: z2 -> ..., '
      'a.3 <== a.4, a.4 resolves: z4 -> ..., '
      '...', () {
    setUp(() {
      tester.sources([
        'a.1',
        'a.3',
        'a.5',
        'a.7',
        'a.9',
        'z2',
        'z4',
        'z6',
        'z8',
        'z10',
      ]);
      // z2 ----> z4 ----
      //   \-> z6 -> z10 -\-> z8
      tester.importGraph({
        'z2': ['z4', 'z6'],
        'z4': ['z8'],
        'z6': ['z10'],
        'z10': ['z8'],
      });
      tester.builder(from: '.1', to: '.2')
        ..reads('.1')
        ..resolvesOther('z2')
        ..writes('.2');
      tester.builder(from: '.3', to: '.4')
        ..reads('.3')
        ..resolvesOther('z4')
        ..writes('.4');
      tester.builder(from: '.5', to: '.6')
        ..reads('.5')
        ..resolvesOther('z6')
        ..writes('.6');
      tester.builder(from: '.7', to: '.8')
        ..reads('.7')
        ..resolvesOther('z8')
        ..writes('.8');
      tester.builder(from: '.9', to: '.10')
        ..reads('.9')
        ..resolvesOther('z10')
        ..writes('.10');
    });

    test('a.2+a.4+a.6+a.8+a.10 are built', () async {
      expect(
        await tester.build(),
        Result(written: ['a.2', 'a.4', 'a.6', 'a.8', 'a.10']),
      );
    });

    test('change z2, a.2 is built', () async {
      await tester.build();
      expect(await tester.build(change: 'z2'), Result(written: ['a.2']));
    });

    test('change z4, a.2+a.4 are built', () async {
      await tester.build();
      expect(await tester.build(change: 'z4'), Result(written: ['a.2', 'a.4']));
    });

    test('change z6, a.2+a.6 are built', () async {
      await tester.build();
      expect(await tester.build(change: 'z6'), Result(written: ['a.2', 'a.6']));
    });

    test('change z8, a.2+a.4+a.6+a.8+a.10 are built', () async {
      await tester.build();
      expect(
        await tester.build(change: 'z8'),
        Result(written: ['a.2', 'a.4', 'a.6', 'a.8', 'a.10']),
      );
    });

    test('change z10, a.2+a.6+a.10 are built', () async {
      await tester.build();
      expect(
        await tester.build(change: 'z10'),
        Result(written: ['a.2', 'a.6', 'a.10']),
      );
    });
  });

  // As the previous group, but "z" sources are all generated.
  group('a.1 <== a.2, a.2 resolves: z.12 -> ..., '
      'a.3 <== a.4, a.4 resolves: z.14 -> ..., '
      '...', () {
    setUp(() {
      tester.sources([
        'a.1',
        'a.3',
        'a.5',
        'a.7',
        'a.9',
        'z.11',
        'z.13',
        'z.15',
        'z.17',
        'z.19',
      ]);
      // z.12 ----> z.14 ----
      //   \-> z.16 -> z.20 -\-> z.18
      tester.importGraph({
        'z.12': ['z.14', 'z.16'],
        'z.14': ['z.18'],
        'z.16': ['z.20'],
        'z.20': ['z.18'],
      });

      // The "z" generators go first so their output is available.
      tester.builder(from: '.11', to: '.12')
        ..reads('.11')
        ..writes('.12');
      tester.builder(from: '.13', to: '.14')
        ..reads('.13')
        ..writes('.14');
      tester.builder(from: '.15', to: '.16')
        ..reads('.15')
        ..writes('.16');
      tester.builder(from: '.17', to: '.18')
        ..reads('.17')
        ..writes('.18');
      tester.builder(from: '.19', to: '.20')
        ..reads('.19')
        ..writes('.20');

      // Followed by the "a" generators.
      tester.builder(from: '.1', to: '.2')
        ..reads('.1')
        ..resolvesOther('z.12')
        ..writes('.2');
      tester.builder(from: '.3', to: '.4')
        ..reads('.3')
        ..resolvesOther('z.14')
        ..writes('.4');
      tester.builder(from: '.5', to: '.6')
        ..reads('.5')
        ..resolvesOther('z.16')
        ..writes('.6');
      tester.builder(from: '.7', to: '.8')
        ..reads('.7')
        ..resolvesOther('z.18')
        ..writes('.8');
      tester.builder(from: '.9', to: '.10')
        ..reads('.9')
        ..resolvesOther('z.20')
        ..writes('.10');
    });

    test('a.2+a.4+a.6+a.8+a.10 are built', () async {
      expect(
        await tester.build(),
        Result(
          written: [
            'z.12',
            'z.14',
            'z.16',
            'z.18',
            'z.20',
            'a.2',
            'a.4',
            'a.6',
            'a.8',
            'a.10',
          ],
        ),
      );
    });

    test('change z.11, z.12+a.2 is built', () async {
      await tester.build();
      expect(
        await tester.build(change: 'z.11'),
        Result(written: ['z.12', 'a.2']),
      );
    });

    test('change z.13, z.14+a.2+a.4 are built', () async {
      await tester.build();
      expect(
        await tester.build(change: 'z.13'),
        Result(written: ['z.14', 'a.2', 'a.4']),
      );
    });

    test('change z.15, z.16+a.2+a.6 are built', () async {
      await tester.build();
      expect(
        await tester.build(change: 'z.15'),
        Result(written: ['z.16', 'a.2', 'a.6']),
      );
    });

    test('change z.17, z.18+a.2+a.4+a.6+a.8+a.10 are built', () async {
      await tester.build();
      expect(
        await tester.build(change: 'z.17'),
        Result(written: ['z.18', 'a.2', 'a.4', 'a.6', 'a.8', 'a.10']),
      );
    });

    test('change z.19, z.20+a.2+a.6+a.10 are built', () async {
      await tester.build();
      expect(
        await tester.build(change: 'z.19'),
        Result(written: ['z.20', 'a.2', 'a.6', 'a.10']),
      );
    });
  });

  // As the previous group, but builder order changed so z.15 <== z.16 is
  // generated after a.1 <== a.2.
  group('builders reordered '
      'a.1 <== a.2, a.2 resolves: z.12 -> ..., '
      'a.3 <== a.4, a.4 resolves: z.14 -> ..., '
      '...', () {
    setUp(() {
      tester.sources([
        'a.1',
        'a.3',
        'a.5',
        'a.7',
        'a.9',
        'z.11',
        'z.13',
        'z.15',
        'z.17',
        'z.19',
      ]);
      // z.12 ----> z.14 ----
      //   \-> z.16 -> z.20 -\-> z.18
      tester.importGraph({
        'z.12': ['z.14', 'z.16'],
        'z.14': ['z.18'],
        'z.16': ['z.20'],
        'z.20': ['z.18'],
      });

      // The "z" generators go first so their output is available;
      // except z.15 <== z.16 which is moved to the block below.
      tester.builder(from: '.11', to: '.12')
        ..reads('.11')
        ..writes('.12');
      tester.builder(from: '.13', to: '.14')
        ..reads('.13')
        ..writes('.14');
      tester.builder(from: '.17', to: '.18')
        ..reads('.17')
        ..writes('.18');
      tester.builder(from: '.19', to: '.20')
        ..reads('.19')
        ..writes('.20');

      // Followed by the "a" generators.
      tester.builder(from: '.1', to: '.2')
        ..reads('.1')
        ..resolvesOther('z.12')
        ..writes('.2');
      tester.builder(from: '.15', to: '.16') // And z.15 <== z.16.
        ..reads('.15')
        ..writes('.16');
      tester.builder(from: '.3', to: '.4')
        ..reads('.3')
        ..resolvesOther('z.14')
        ..writes('.4');
      tester.builder(from: '.5', to: '.6')
        ..reads('.5')
        ..resolvesOther('z.16')
        ..writes('.6');
      tester.builder(from: '.7', to: '.8')
        ..reads('.7')
        ..resolvesOther('z.18')
        ..writes('.8');
      tester.builder(from: '.9', to: '.10')
        ..reads('.9')
        ..resolvesOther('z.20')
        ..writes('.10');
    });

    // Same as previous group; unchanged by z.15 <== z.16 change.
    test('a.2+a.4+a.6+a.8+a.10 are built', () async {
      expect(
        await tester.build(),
        Result(
          written: [
            'z.12',
            'z.14',
            'z.16',
            'z.18',
            'z.20',
            'a.2',
            'a.4',
            'a.6',
            'a.8',
            'a.10',
          ],
        ),
      );
    });

    // Same as previous group; unchanged by z.15 <== z.16 change.
    test('change z.11, z.12+a.2 is built', () async {
      await tester.build();
      expect(
        await tester.build(change: 'z.11'),
        Result(written: ['z.12', 'a.2']),
      );
    });

    // Same as previous group; unchanged by z.15 <== z.16 change.
    test('change z.13, z.14+a.2+a.4 are built', () async {
      await tester.build();
      expect(
        await tester.build(change: 'z.13'),
        Result(written: ['z.14', 'a.2', 'a.4']),
      );
    });

    // Changed from previous group: z.15 <== z.16 is now generated too late to
    // affect a.2, so it is not regenerated.
    test('change z.15, z.16+a.2+a.6 are built', () async {
      await tester.build();
      expect(
        await tester.build(change: 'z.15'),
        Result(written: ['z.16', 'a.6']),
      );
    });

    // Same as previous group; unchanged by z.15 <== z.16 change.
    test('change z.17, z.18+a.2+a.4+a.6+a.8+a.10 are built', () async {
      await tester.build();
      expect(
        await tester.build(change: 'z.17'),
        Result(written: ['z.18', 'a.2', 'a.4', 'a.6', 'a.8', 'a.10']),
      );
    });

    // Changed from previous group: z.15 <== z.16 is now generated too late to
    // affect a.2, so it is not regenerated.
    test('change z.19, z.20+a.2+a.6+a.10 are built', () async {
      await tester.build();
      expect(
        await tester.build(change: 'z.19'),
        Result(written: ['z.20', 'a.6', 'a.10']),
      );
    });
  });
}
