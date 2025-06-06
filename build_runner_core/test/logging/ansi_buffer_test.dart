// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build_runner_core/src/logging/ansi_buffer.dart';
import 'package:test/test.dart';

void main() {
  group('AnsiBuffer', () {
    test('wraps and pads to 80 cols', () {
      final buffer = AnsiBuffer();
      buffer.writeLine(['0123456789' * 10]);
      expect(buffer.lines, ['0123456789' * 8, '0123456789' * 2 + ' ' * 60]);
    });

    test('wraps at whitespace and pads to 80 cols', () {
      final buffer = AnsiBuffer();
      buffer.writeLine(['012345678 abcde' * 6]);
      expect(buffer.lines, [
        '${'012345678 abcde' * 4}012345678'.padRight(80),
        'abcde012345678 abcde'.padRight(80),
      ]);
    });

    test('wraps at previous item whitespace and pads to 80 cols', () {
      final buffer = AnsiBuffer();
      buffer.writeLine(['01234 6789', '0123456789' * 8]);

      expect(buffer.lines, ['01234', '6789${'0123456789' * 7}012345', '6789']);
    });

    // TODO: items > two lines
  });
}
