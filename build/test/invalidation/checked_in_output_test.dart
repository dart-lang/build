// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import 'invalidation_tester.dart';

void main() {
  late InvalidationTester tester;

  setUp(() {
    tester = InvalidationTester();

    // Start with output source on disk.
    //
    // The ordering of sources matters because a different codepath in
    // `graph.dart` is triggered depending on whether a source is first
    // processed as an input or as a generated output of another input.
    //
    // So for `a` have the output come first, and for `b` the input come
    // first.
    tester.sources(['a.g', 'a', 'b', 'b.g']);
  });

  group('a <== a.g, a <== a.other', () {
    setUp(() {
      tester.builder(from: '', to: '.g', outputIsVisible: true)
        ..reads('')
        ..writes('.g');

      tester.builder(from: '', to: '.other', outputIsVisible: true)
        ..reads('')
        ..writes('.other');
    });

    test('checked in outputs are not treated as inputs', () async {
      expect(
        await tester.build(),
        // If outputs were treated by inputs there would be outputs created like
        // `a.g.g.other`.
        Result(
          written: [
            'a.g',
            'a.other',
            'a.g.other',
            'b.g',
            'b.other',
            'b.g.other',
          ],
        ),
      );
    });
  });
}
