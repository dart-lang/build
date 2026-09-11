// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build_runner/src/build/prefix_for_phase.dart';
import 'package:test/test.dart';

void main() {
  group('prefixForPhase', () {
    test('throws ArgumentError on negative phase', () {
      expect(() => prefixForPhase(-1), throwsArgumentError);
    });

    test(
      'generates single-letter base62 identifiers with single dollar prefix',
      () {
        expect(prefixForPhase(0), r'$a');
        expect(prefixForPhase(1), r'$b');
        expect(prefixForPhase(25), r'$z');
        expect(prefixForPhase(26), r'$A');
        expect(prefixForPhase(51), r'$Z');
        expect(prefixForPhase(52), r'$0');
        expect(prefixForPhase(61), r'$9');
      },
    );

    test(
      'generates two-character base62 identifiers with double dollar prefix',
      () {
        expect(prefixForPhase(62), r'$$aa');
        expect(prefixForPhase(63), r'$$ab');
        expect(prefixForPhase(62 + 25), r'$$az');
        expect(prefixForPhase(62 + 26), r'$$aA');
        expect(prefixForPhase(62 + 61), r'$$a9');
        expect(prefixForPhase(62 + 62 * 62 - 1), r'$$99');
      },
    );

    test(
      'generates three-character base62 identifiers with triple dollar prefix',
      () {
        expect(prefixForPhase(62 + 62 * 62), r'$$$aaa');
      },
    );
  });
}
