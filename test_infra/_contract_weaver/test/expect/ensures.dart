// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'contracts.dart';

class Calculator {
  @Ensures('result >= 0')
  int abs(int x) {
    if (x < 0) return -x;
    return x;
  }

  @Ensures('result.length == count')
  List<int> zeros(int count) => List.filled(count, 0);
}
