// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'contracts.dart';

class Calculator {
  @Requires('x > 0')
  @Requires('y > 0')
  int add(int x, int y) {
    return x + y;
  }

  @Requires('x >= 0')
  int half(int x) => x ~/ 2;
}
