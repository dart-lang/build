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

    test('is the phase number preceded by a dollar', () {
      expect(prefixForPhase(0), r'$0');
      expect(prefixForPhase(1), r'$1');
      expect(prefixForPhase(9), r'$9');
      expect(prefixForPhase(43), r'$43');
      expect(prefixForPhase(1234), r'$1234');
    });
  });
}
