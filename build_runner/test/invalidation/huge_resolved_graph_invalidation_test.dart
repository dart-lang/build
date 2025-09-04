// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import 'invalidation_tester.dart';

/// Invalidation tests for huge resolved transitive deps graphs.
///
/// In addition to testing serialized JSON size, this ensures there are no stack
/// overflows due to walking the graph using recursion.
void main() {
  late InvalidationTester tester;

  setUp(() {
    tester = InvalidationTester();
  });

  // This was sufficient to cause a stack overflow when `Build` used a recursive
  // algorithm to check for changes to graphs.
  final size = 1500;

  group('a.1 <== a.2, a.2 resolves z1 --> ... --> z$size', () {
    setUp(() {
      tester.sources(['a.1', for (var i = 1; i != (size + 1); ++i) 'z$i']);
      tester.importGraph({
        for (var i = 1; i != size; ++i) 'z$i': ['z${i + 1}'],
      });
      tester.builder(from: '.1', to: '.2')
        ..resolvesOther('z1')
        ..writes('.2');
    });

    test('a.2 is built', () async {
      expect(await tester.build(), Result(written: ['a.2']));
    });

    test('change z$size, a.2 is rebuilt', () async {
      await tester.build();
      expect(await tester.build(change: 'z$size'), Result(written: ['a.2']));
    });

    test('asset graph size', () async {
      await tester.build();
      // Currently measured at 276k; doesn't need to be a precise check, this is
      // to guard against quadratic behaviour which would cause size >> 1Mb.
      expect(tester.assetGraphSize, lessThan(300000));
    });
  });
}
