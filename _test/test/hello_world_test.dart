// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('browser')
library;

import 'dart:js_interop';

import 'package:_test/app.dart';
import 'package:test/test.dart';
import 'package:web/web.dart';

//import_anchor

import 'common/message.dart';

void main() {
  setUp(startApp);

  tearDown(() {
    document.body!.innerHTML = ''.toJS;
  });

  test('hello world', () {
    expect(document.body!.innerText, contains(message));
  });

  test('failing test', skip: 'Expected failure', () {
    expect(true, isFalse);
  });
}
