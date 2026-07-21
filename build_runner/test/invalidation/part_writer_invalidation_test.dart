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

  group('part writer invalidation', () {
    setUp(() {
      tester.sources(['a', 'b']);
      tester.builder(from: '', to: '.1')
        ..readsOther('b')
        ..writesPart('// part from builder 1');
      tester.builder(from: '', to: '.2').writesPart('// part from builder 2');
    });

    test('initial build writes the generated part', () async {
      expect(await tester.build(), Result(written: ['_br_/a', '_br_/b']));
    });

    test('change b, part is rewritten because builder 1 ran, but builder 2 is '
        'cached', () async {
      await tester.build();
      // change b invalidated builder 1 on a, but builder 2 on a is cached
      expect(
        await tester.build(change: 'b'),
        Result(written: ['_br_/a', '_br_/b']),
      );
    });

    test('no-op build does not rewrite part', () async {
      await tester.build();
      expect(await tester.build(), Result());
    });
  });

  group('builder resolving shared part invalidation', () {
    setUp(() {
      tester.sources(['a.dart', 'b.dart', 'c.dart']);
      // 'c.dart' resolves 'a.dart', which has a part contribution.
      tester.importGraph({
        'c.dart': ['a.dart'],
      });
      // Builder 1 writes a part for 'a.dart'. It depends on 'b.dart', so changing 'b.dart' forces it to rerun
      // and generate a new _br_/a.dart.
      tester.builder(from: '.dart', to: '.1.dart')
        ..readsOther('b.dart')
        ..writesPart('// part from builder 1');

      // Builder 2 resolves 'a.dart'. It's applied to 'c.dart'.
      tester.builder(from: '.dart', to: '.2.dart')
        ..reads('.dart') // reads 'c.dart'
        ..resolvesOther('a.dart')
        ..writes('.2.dart'); // writes 'c.2.dart'
    });

    test('initial build writes the part and the output', () async {
      final result = await tester.build();
      expect(
        result,
        Result(
          written: [
            '_br_/a.dart',
            '_br_/b.dart',
            '_br_/c.dart',
            'a.2.dart',
            'b.2.dart',
            'c.2.dart'
          ],
        ),
      );
    });

    test('change b.dart, part is rewritten, and c.2.dart IS rebuilt', () async {
      await tester.build();
      // change b.dart invalidates builder 1 on a.dart, rewriting _br_/a.dart.
      // But c.2.dart should be rebuilt because it resolves a.dart!
      expect(
        await tester.build(change: 'b.dart'),
        Result(
          written: [
            '_br_/a.dart',
            '_br_/b.dart',
            '_br_/c.dart',
            'a.2.dart',
            'b.2.dart',
            'c.2.dart'
          ],
        ),
      );
    });
  });

  group('optional builder writing shared part', () {
    setUp(() {
      tester.sources(['a.dart', 'c.dart']);
      // 'c.dart' resolves 'a.dart', which has a part contribution.
      tester.importGraph({
        'c.dart': ['a.dart'],
      });
      // Builder 1 writes a part for 'a.dart', but is optional!
      tester.builder(from: '.dart', to: '.1.foo', isOptional: true)
        ..writesPart('// part from optional builder 1')
        ..writes('.1.foo');

      // Builder 2 resolves 'a.dart'. It's applied to 'c.dart', forcing analysis of 'a.dart'.
      tester.builder(from: '.dart', to: '.2.txt')
        ..reads('.dart') // reads 'c.dart'
        ..resolvesOther('a.dart')
        ..writes('.2.txt'); // writes 'c.2.txt'
    });

    test('initial build executes the optional part builder', () async {
      final result = await tester.build();
      // Because c.2.txt depends on resolving a.dart, and a.dart has a potential part,
      // the optional builder *should* run!
      expect(
        result,
        Result(
          written: [
            '_br_/a.dart',
            'a.1.foo',
            'a.2.txt',
            'c.2.txt'
          ],
        ),
      );
    });
  });
}
