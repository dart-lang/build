// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/src/logging/ansi_buffer.dart';
import 'package:build/src/logging/build_log.dart';
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

    test('indents, wraps and pads to 80 cols', () {
      final buffer = AnsiBuffer();
      buffer.writeLine(['012345678 ' * 10], indent: 5);
      expect(buffer.lines, [
        '     ${'012345678 ' * 7}'.padRight(80),
        '     ${'012345678 ' * 3}'.padRight(80),
      ]);
    });

    test('indents, wraps with smaller hanging indent and pads to 80 cols', () {
      final buffer = AnsiBuffer();
      buffer.writeLine(['012345678 ' * 10], indent: 5, hangingIndent: 3);
      expect(buffer.lines, [
        '     ${'012345678 ' * 7}'.padRight(80),
        '   ${'012345678 ' * 3}'.padRight(80),
      ]);
    });

    test('indents, wraps with larger hanging indent and pads to 80 cols', () {
      final buffer = AnsiBuffer();
      buffer.writeLine(['012345678 ' * 10], indent: 5, hangingIndent: 10);
      expect(buffer.lines, [
        '     ${'012345678 ' * 7}'.padRight(80),
        '          ${'012345678 ' * 3}'.padRight(80),
      ]);
    });

    test('indent is limited to width ~/ 2', () {
      final buffer = AnsiBuffer();
      buffer.writeLine(['012345678 ' * 8], indent: 100);
      expect(buffer.lines, [
        ' ' * 40 + '012345678 ' * 4,
        ' ' * 40 + '012345678 ' * 4,
      ]);
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
        '${'012345678 abcde' * 5}01234',
        '5678 abcde'.padRight(80),
      ]);
    });

    test('line that fits width with hanging indent does not write '
        'empty line', () {
      final buffer = AnsiBuffer();
      buffer.writeLine(['0123456789' * 8], hangingIndent: 2);
      expect(buffer.lines, ['0123456789' * 8]);
    });

    test('hanging indent is limited to width ~/ 2', () {
      final buffer = AnsiBuffer();
      buffer.writeLine([
        '012345678${AnsiBuffer.nbsp}abcde' * 6,
      ], hangingIndent: 81);
      expect(buffer.lines, [
        '${'012345678 abcde' * 4}012345678 abcde01234',
        (' ' * 40 + '5678 abcde').padRight(80),
      ]);
    });

    test('overflow that overflows due to hangingIndent is wrapped', () {
      final buffer = AnsiBuffer();
      buffer.writeLine([
        '0123456789',
        ' ',
        '0123456789' * 9,
      ], hangingIndent: 40);
      expect(buffer.lines, [
        '0123456789'.padRight(80),
        ' ' * 40 + '0123456789' * 4,
        (' ' * 40 + ('0123456789' * 4)).padRight(80),
        (' ' * 40 + '0123456789').padRight(80),
      ]);
    });
  });
}
