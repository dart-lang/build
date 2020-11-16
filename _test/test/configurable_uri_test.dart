// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import 'common/message.dart'
    if (dart.library.io) 'common/message_io.dart'
    if (dart.library.html) 'common/message_html.dart';

import 'common/message_export.dart' as exported;

void main() {
  group('browser', () {
    test('imports', () {
      expect(message, contains('Javascript'));
    });

    test('exports', () {
      expect(exported.message, contains('Javascript'));
    });
  }, testOn: 'browser');

  group('vm', () {
    test('imports', () {
      expect(message, contains('VM'));
    });

    test('exports', () {
      expect(exported.message, contains('VM'));
    });
  }, testOn: 'vm');
}
