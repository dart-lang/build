// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Expressions that span lines, so that woven code must keep every original
// token on its original line for stack traces to stay accurate.
import 'contracts.dart';

@Invariant('total >= 0')
class Ledger {
  int total = 0;

  @Requires('amount > 0')
  @Ensures('result == total')
  int add(int amount) {
    total += amount;
    return total + 0;
  }

  @Ensures('result >= 0')
  int twice(int x) => x.abs() + x.abs();

  @Ensures('result.isNotEmpty')
  Future<String> describe() async {
    return Future.value('total: $total');
  }

  @Ensures('total >= 0')
  void reset() {
    if (total > 100) {
      total = 0;
      return;
    }
    total = total ~/ 2;
  }

  @Ensures('result.length == count')
  Future<List<int>> zeros(int count) => Future.value(List.filled(count, 0));
}

@Invariant('width > 0')
class Box {
  final int width;

  @Requires('width > 0')
  Box(this.width) {
    if (width > 10) {
      return;
    }
    print('small');
  }
}
