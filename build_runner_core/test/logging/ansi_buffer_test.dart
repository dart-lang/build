// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build_runner_core/src/logging/ansi_buffer.dart';
import 'package:build_runner_core/src/logging/build_log.dart';
import 'package:test/test.dart';

void main() {
  group('AnsiBuffer', () {
    setUp(() {
      BuildLog.resetForTests(consoleWidth: 80);
    });

    test('wraps and pads to 80 cols', () {
      final buffer = AnsiBuffer();
      buffer.writeLine(['0123456789' * 10]);
      expect(buffer.lines, ['0123456789' * 8, ('0123456789' * 2).padRight(80)]);
    });

    test('wraps very long lines and pads to 80 cols', () {
      final buffer = AnsiBuffer();
      buffer.writeLine(['0123456789' * 20]);
      expect(buffer.lines, [
        '0123456789' * 8,
        '0123456789' * 8,
        ('0123456789' * 4).padRight(80),
      ]);
    });

    test('wraps at whitespace and pads to 80 cols', () {
      final buffer = AnsiBuffer();
      buffer.writeLine(['012345678 abcde' * 6]);
      expect(buffer.lines, [
        '${'012345678 abcde' * 4}012345678'.padRight(80),
        'abcde012345678 abcde'.padRight(80),
      ]);
    });

    test('wraps at whitespace and pads to 80 cols ignoring ANSI codes', () {
      final buffer = AnsiBuffer();
      buffer.writeLine([
        '012345678 abcde' * 3,
        AnsiBuffer.reset,
        '012345678 abcde' * 3,
      ]);
      expect(buffer.lines.map(AnsiBuffer.removeAnsi).toList(), [
        '${'012345678 abcde' * 4}012345678'.padRight(80),
        'abcde012345678 abcde'.padRight(80),
      ]);
    });

    test('wraps at previous item whitespace and pads to 80 cols', () {
      final buffer = AnsiBuffer();
      buffer.writeLine(['01234 6789', '0123456789' * 8]);

      expect(buffer.lines, [
        '01234'.padRight(80),
        '6789${'0123456789' * 7}012345',
        '6789'.padRight(80),
      ]);
    });

    test('wraps very long lines at whitespace and pads to 80 cols', () {
      final buffer = AnsiBuffer();
      buffer.writeLine(['0123456789' * 10 + '012345678 abcde' * 6]);
      expect(buffer.lines, [
        '0123456789' * 8,
        '${'0123456789' * 2}${'012345678 abcde' * 3}012345678'.padRight(80),
        'abcde${'012345678 abcde' * 2}'.padRight(80),
      ]);
    });

    test('does not wrap at nbsp, replaces with space', () {
      final buffer = AnsiBuffer();
      buffer.writeLine(['012345678${AnsiBuffer.nbsp}abcde' * 6]);
      expect(buffer.lines, [
        '${'012345678 abcde' * 4}012345678 abcde01234',
        '5678 abcde'.padRight(80),
      ]);
    });
  });
}
