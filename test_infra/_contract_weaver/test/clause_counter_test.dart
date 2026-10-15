// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_contract_weaver/src/clause_counter.dart';
import 'package:test/test.dart';

void main() {
  group('ClauseCounter', () {
    test('counts each contract annotation by name', () {
      expect(
        ClauseCounter.count('''
@Invariant('a')
class C {
  @Requires('b')
  @Requires('c')
  @Ensures('d')
  @ThrowEnsures(StateError, 'e')
  void f() {}
}
'''),
        {'Requires': 2, 'Ensures': 1, 'ThrowEnsures': 1, 'Invariant': 1},
      );
    });

    test('does not count other annotations', () {
      expect(
        ClauseCounter.count('''
@Require('a')
@override
void f() {}
'''),
        {'Requires': 0, 'Ensures': 0, 'ThrowEnsures': 0, 'Invariant': 0},
      );
    });
  });
}
