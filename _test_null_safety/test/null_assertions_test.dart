// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Opt out of null safety
// @dart=2.9

// Null assertions are only supported on the web right now.
@TestOn('browser')
import 'package:test/test.dart';

import 'common/message.dart';

void main() {
  test('null assertions work in weak mode', () {
    expect(() => printString(null), throwsA(isA<AssertionError>()));
  });
}
