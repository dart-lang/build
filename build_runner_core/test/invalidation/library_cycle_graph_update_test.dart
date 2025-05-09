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
}
