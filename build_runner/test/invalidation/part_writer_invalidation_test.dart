// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
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
      expect(
        await tester.build(),
        Result(written: ['_br_/a.part', '_br_/b.part']),
      );
    });

    test('change b, part is rewritten because builder 1 ran, but builder 2 is '
        'cached', () async {
      await tester.build();
      // change b invalidated builder 1 on a, but builder 2 on a is cached
      expect(
        await tester.build(change: 'b'),
        Result(written: ['_br_/a.part', '_br_/b.part']),
      );
    });

    test('no-op build rebuilds nothing', () async {
      await tester.build();
      expect(await tester.build(), Result());
    });

    test('delete a, _br_/a is deleted', () async {
      await tester.build();
      expect(await tester.build(delete: 'a'), Result(deleted: ['_br_/a.part']));
    });
  });

  group('builder resolving shared part invalidation', () {
    setUp(() {
      tester.sources(['a', 'b', 'c']);
      // 'c' resolves 'a', which has a part contribution.
      tester.importGraph({
        'c': ['a'],
      });
      tester.partGraph({
        'a': ['_br_/a.part'],
      });
      // Builder 1 writes a part for 'a'. It depends on 'b', so
      // changing 'b' forces it to rerun and generate a new _br_/a.
      tester.builder(from: '', to: '.1')
        ..readsOther('b')
        ..writesPart('_digest');

      // Builder 2 resolves 'a'. It's applied to 'c'.
      tester.builder(from: '', to: '.2')
        ..reads('') // reads 'c'
        ..resolvesOther('a')
        ..writes('.2'); // writes 'c.2'
    });

    test('initial build writes the part and the output', () async {
      final result = await tester.build();
      expect(
        result,
        Result(
          written: [
            '_br_/a.part',
            '_br_/b.part',
            '_br_/c.part',
            'a.2',
            'b.2',
            'c.2',
          ],
        ),
      );
    });

    test('change b, part is rewritten, and c.2 IS rebuilt', () async {
      await tester.build();
      // change b invalidates builder 1 on a, rewriting _br_/a.
      // But c.2 should be rebuilt because it resolves a!
      expect(
        await tester.build(change: 'b'),
        Result(
          written: [
            '_br_/a.part',
            '_br_/b.part',
            '_br_/c.part',
            'a.2',
            'b.2',
            'c.2',
          ],
        ),
      );
    });

    test('no-op build rebuilds nothing', () async {
      await tester.build();
      expect(await tester.build(), Result());
    });
  });

  group(
    'builder resolving shared part invalidation when part is unchanged',
    () {
      setUp(() {
        tester.sources(['a', 'b', 'c']);
        tester.importGraph({
          'c': ['a'],
        });
        tester.partGraph({
          'a': ['_br_/a.part'],
        });
        tester.builder(from: '', to: '.1')
          ..readsOther('b')
          ..writesPart('// part from builder 1');

        tester.builder(from: '', to: '.2')
          ..reads('')
          ..resolvesOther('a')
          ..writes('.2');
      });

      test('change b when part is unchanged does not rebuild c.2', () async {
        await tester.build();
        expect(
          await tester.build(change: 'b'),
          Result(written: ['_br_/a.part', '_br_/b.part', '_br_/c.part', 'b.2']),
        );
      });

      test('no-op build rebuilds nothing', () async {
        await tester.build();
        expect(await tester.build(), Result());
      });
    },
  );

  group('optional builder writing shared part', () {
    test(
      'throws ArgumentError when builder is both optional and writes a part',
      () async {
        tester.sources(['a.dart']);
        tester.builder(from: '.dart', to: '.1.foo', isOptional: true)
          ..writesPart('// part from optional builder 1')
          ..writes('.1.foo');
        expect(() => tester.build(), throwsA(isArgumentError));
      },
    );
  });

  group('shared part import invalidation', () {
    setUp(() {
      // Imports in parts need the "Parts with Imports" language feature.
      tester = InvalidationTester(enabledExperiments: ['enhanced-parts']);
      tester.sources(['a', 'b', 'c']);

      // 'c' resolves 'a', which has a part contribution.
      tester.importGraph({
        'c': ['a'],
      });
      tester.partGraph({
        'a': ['_br_/a.part'],
      });

      // Builder 1 adds an import of 'b' to the shared part, and source that
      // uses it. The source is fixed and the builder reads nothing, so the
      // part content never changes: only the import edge can invalidate.
      tester.builder(from: '', to: '.1')
        ..writesPartImport('b')
        ..writesPart('// uses b');

      // Builder 2 resolves 'a'. It's applied to 'c'.
      tester.builder(from: '', to: '.2')
        ..reads('') // reads 'c'
        ..resolvesOther('a')
        ..writes('.2'); // writes 'c.2'
    });

    test('initial build writes the parts and the outputs', () async {
      expect(
        await tester.build(),
        Result(
          written: [
            '_br_/a.part',
            '_br_/b.part',
            '_br_/c.part',
            'a.2',
            'b.2',
            'c.2',
          ],
        ),
      );
      expect(
        tester.readerWriter!.testing.readString('_br_/a.part'.assetId),
        contains("import 'package:pkg/b.dart'"),
      );
    });

    test("change b, c.2 IS rebuilt because a's part imports b", () async {
      await tester.build();
      // The part of 'a' is unchanged: builder 1 does not read 'b', it only
      // imports it. But 'a' now depends on 'b' through that import, so
      // everything that resolves 'a' must rebuild.
      expect(
        await tester.build(change: 'b'),
        Result(written: ['_br_/b.part', 'a.2', 'b.2', 'c.2']),
      );
    });
  });

  group('shared part import invalidation, resolver in last part phase', () {
    setUp(() {
      // Imports in parts need the "Parts with Imports" language feature.
      tester = InvalidationTester(enabledExperiments: ['enhanced-parts']);
      tester.sources(['a', 'b', 'c']);

      tester.importGraph({
        'c': ['a'],
      });
      tester.partGraph({
        'a': ['_br_/a.part'],
      });

      tester.builder(from: '', to: '.1')
        ..writesPartImport('b')
        ..writesPart('// uses b');

      // The builder that resolves also writes a part, so it is the last phase
      // that adds to a library: the shared part content is never final while
      // the build is running.
      tester.builder(from: '', to: '.2')
        ..reads('')
        ..resolvesOther('a')
        ..writes('.2')
        ..writesPart('// from builder 2');
    });

    test('change b, everything that resolves a is rebuilt', () async {
      await tester.build();
      expect(
        await tester.build(change: 'b'),
        Result(
          written: [
            '_br_/a.part',
            '_br_/b.part',
            '_br_/c.part',
            'a.2',
            'b.2',
            'c.2',
          ],
        ),
      );
    });
  });
}
