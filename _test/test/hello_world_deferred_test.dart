// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('browser')
library;

import 'dart:js_interop';

import 'package:_test/app.dart';
import 'package:test/test.dart';
import 'package:web/web.dart';

import 'common/message.dart' deferred as m;

void main() {
  setUp(() => startApp(text: 'Hello World!'));

  tearDown(() {
    document.body!.innerHTML = ''.toJS;
  });

  test('hello world', () async {
    await m.loadLibrary();
    expect(document.body?.innerText, contains(m.message));
  });
}
