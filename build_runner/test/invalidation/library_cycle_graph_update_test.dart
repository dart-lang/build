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

  // Builds a.2 and a.3 both resolve z; the resolved library cycle graph
  // differs because z.4 is generated between a.2 and a.3.
  group('a.1 <== a.2, a.1 <== a.3, z.4 <== z.5, '
      'a.2 resolves: z --> z.5, a.3 resolves: z --> z.5 --> z2', () {
    setUp(() {
      tester = InvalidationTester();
      tester.sources(['a.1', 'x1', 'z', 'z.4', 'z2']);
      tester.importGraph({
        'z': ['z.5'],
        'z.5': ['z2'],
      });

      tester.builder(from: '.1', to: '.2')
        ..reads('.1')
        ..readsOther('x1')
        ..resolvesOther('z')
        ..writes('.2');

      tester.builder(from: '.4', to: '.5')
        ..reads('.4')
        ..writes('.5');

      tester.builder(from: '.1', to: '.3')
        ..reads('.1')
        ..resolvesOther('z')
        ..writes('.3');
    });

    test('a.2+a.3 are built', () async {
      expect(await tester.build(), Result(written: ['a.2', 'z.5', 'a.3']));
    });

    test('change z2, a.3 is rebuilt', () async {
      await tester.build();
      expect(await tester.build(change: 'z2'), Result(written: ['a.3']));
    });

    test('partial library cycle graph update does not lose data', () async {
      // Full build: full library cycle graph is computed.
      expect(await tester.build(), Result(written: ['a.2', 'z.5', 'a.3']));
      // Trigger only a.2: library cycle graph is only computed up to a.2 phase.
      expect(await tester.build(change: 'x1'), Result(written: ['a.2']));

      // Next build still needs the full library cycle graph, if it succeeds
      // part of the graph was retained from the first build.
      expect(await tester.build(), Result());

      // Change using the graph still rebuilds as expected.
      expect(await tester.build(change: 'z2'), Result(written: ['a.3']));
    });
  });

  // A build that causes incomplete library graph data to be stored
  // along with complete data changing at a later phase. This checks that
  // phased data is not cut off at the first incomplete phase.
  group('a1 <== [a.2] <== [a.3], a.4 <== a.5 <== a.6, '
      'a.2 resolves: z3 -> a.3, '
      'a.6 resolves: a.5, '
      'b.5 reads: a.2', () {
    setUp(() {
      tester.sources(['a.1', 'z3', 'a.4', 'b.4']);
      tester.importGraph({
        'z3': ['a.3'],
      });
      tester.builder(from: '.1', to: '.2', isOptional: true)
        ..reads('.1')
        // This tries to resolve z3 -> a.3 when a.3 is not yet available,
        // causing incomplete data.
        ..resolvesOther('z3')
        ..writes('.2');
      tester.builder(from: '.2', to: '.3', isOptional: true)
        ..reads('.2')
        ..writes('.3');
      tester.builder(from: '.4', to: '.5')
        ..reads('.4')
        ..writes('.5');
      tester.builder(from: '.5', to: '.6')
        ..reads('.5')
        // Resolve onto a.5 means there is library cycle graph data used which
        // changes at that (late) phase.
        ..resolvesOther('a.5', forInput: 'a.5')
        // Then read a.2 to trigger resolve of z3 at an earlier phase. It reads
        // incomplete data and marks it for reading "at a later phase", but no
        // more reads are done at a later phase so it remains incomplete.
        ..readsOther('a.2', forInput: 'b.5')
        ..writes('.6');
    });

    test('can rebuild with no changes', () async {
      expect(
        await tester.build(),
        Result(written: ['a.2', 'a.5', 'b.5', 'a.6', 'b.6']),
      );
      expect(await tester.build(), Result());
    });
  });
}
