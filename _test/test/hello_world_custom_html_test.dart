// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('browser')
library;

import 'package:test/test.dart';
import 'package:web/web.dart';

void main() {
  test('can use custom html', () {
    expect(document.getElementById('my-element'), isNotNull);
  });
}
