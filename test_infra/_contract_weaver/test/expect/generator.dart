// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'contracts.dart';

@Invariant('limit >= 0')
class Counter {
  final int limit;

  Counter(this.limit);

  // A generator is not an invariant scope: an abandoned iterator would never
  // leave it.
  @Requires('step > 0')
  Iterable<int> count(int step) sync* {
    for (var i = 0; i < limit; i += step) {
      yield i;
    }
  }
}
