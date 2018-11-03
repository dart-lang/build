// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

// ignore: uri_does_not_exist
import 'common/message.dart'
    // ignore: uri_does_not_exist
    if (dart.library.io) 'common/message_io.dart'
    // ignore: uri_does_not_exist
    if (dart.library.html) 'common/message_html.dart';

main() {
  test('Message matches expected', () {
    if (1.0 is int) {
      expect(message, contains('Javascript'));
    } else {
      expect(message, contains('VM'));
    }
  });
}
