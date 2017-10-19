// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('browser')
import 'dart:html';

import 'package:test/test.dart';

import 'package:e2e_example/app.dart';

import 'common/message.dart';

void main() {
  setUp(() {
    startApp();
  });

  tearDown(() {
    document.body.innerHtml = '';
  });

  test('hello world', () {
    expect(document.body.text, contains(message));
  });
}
