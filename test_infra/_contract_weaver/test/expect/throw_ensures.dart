// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'contracts.dart';

class Queue {
  final List<int> _items = [];

  // Each clause holds if `take` throws that type. They do not require it to
  // throw: an empty queue that returned normally would not be reported.
  @ThrowEnsures(StateError, '_items.isEmpty')
  @ThrowEnsures(StateError, 'signal.message == "empty"')
  @ThrowEnsures(ArgumentError, 'index < 0 || index >= _items.length')
  int take(int index) {
    if (_items.isEmpty) throw StateError('empty');
    if (index < 0) throw ArgumentError.value(index);
    return _items.removeAt(index);
  }
}
