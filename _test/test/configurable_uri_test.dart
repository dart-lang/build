// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import 'common/message.dart'
    if (dart.library.io) 'common/message_io.dart'
    if (dart.library.html) 'common/message_html.dart'
    if (dart.library.ffi) 'common/message_ffi_without_io.dart';

import 'common/message_export.dart' as exported;

void main() {
  group('browser', () {
    test('imports', () {
      expect(message, contains('Javascript'));
    });

    test('exports', () {
      expect(exported.message, contains('Javascript'));
    });
  }, testOn: 'browser && !dart2wasm');

  group('wasm', () {
    test('imports', () {
      expect(message, contains('WebAssembly'));
    });

    test('exports', () {
      expect(exported.message, contains('WebAssembly'));
    });
  }, testOn: 'dart2wasm');

  group('vm', () {
    test('imports', () {
      expect(message, contains('VM'));
    });

    test('exports', () {
      expect(exported.message, contains('VM'));
    });
  }, testOn: 'vm');
}
