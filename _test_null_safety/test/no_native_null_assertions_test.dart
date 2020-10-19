// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Native null assertions are only supported on the web.
@TestOn('browser')
import 'dart:html';

import 'package:js/js_util.dart' as js_util;
import 'package:test/test.dart';

void main() {
  late final dynamic performance;

  setUpAll(() {
    performance = js_util.getProperty(window, 'performance');
    js_util.setProperty(window, 'performance', null);
    addTearDown(() => js_util.setProperty(window, 'performance', performance));
  });

  test('native null assertions can be disabled', () {
    expect(window.performance, null);
  });
}
