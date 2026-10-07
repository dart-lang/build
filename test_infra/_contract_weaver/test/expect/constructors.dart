// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'contracts.dart';

@Invariant('width > 0')
class Box {
  final int width;

  @Requires('width > 0')
  Box(this.width);

  @Requires('size > 0')
  Box.square(int size) : width = size {
    print('square');
  }

  @Requires('width > 0')
  @Ensures('result.width == width')
  factory Box.cached(int width) {
    return Box(width);
  }
}
