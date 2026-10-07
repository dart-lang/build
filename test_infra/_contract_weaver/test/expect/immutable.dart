// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'contracts.dart';

/// Stands in for `immutable` from `package:meta`, which is matched by name.
const immutable = Object();

/// Declared immutable, so the invariant is checked only on construction.
@immutable
@Invariant('low <= high')
class Range {
  final int low;
  final int high;

  Range(this.low, this.high);

  bool contains(int x) => low <= x && x <= high;
}
