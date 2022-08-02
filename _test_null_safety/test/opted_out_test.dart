// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// @dart=2.7
import 'package:test/test.dart';

import 'common/message.dart';

void main() {
  test('can use null safety', () {
    expect(message.isNotEmpty, true);
  });
}
