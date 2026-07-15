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
}
