// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Disabling sound null safety is only supported on the web right now.
@TestOn('browser')
import 'package:test/test.dart';

const weakMode = <int?>[] is List<int>;

void main() {
  test('sound null safety is disabled', () {
    expect(weakMode, isTrue);
  });
}
