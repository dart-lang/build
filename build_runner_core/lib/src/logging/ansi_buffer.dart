// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

class AnsiBuffer {
  static const String nbsp = '\u00A0';

  static const String reset = '\x1B[0m';
  static const String bold = '\x1B[1m';
  static const String red = '\x1B[31m';
  static const String green = '\x1B[32m';

  final List<String> lines = [];

  bool _isAnsi(String item) =>
      item == reset || item == bold || item == red || item == green;

  void write(AnsiBufferLine line) {
    writeLine(
      line.items,
      indent: line.indent,
      hangingIndent: line.hangingIndent,
    );
  }

  void writeLine(List<String> items, {int indent = 0, int? hangingIndent}) {
    final width = stdout.hasTerminal ? stdout.terminalColumns : 80;
    hangingIndent ??= indent;

    final buffer = StringBuffer(' ' * indent);
    var lengthIgnoringAnsi = indent;
    int? lastWhitespaceIndex;
    int? lastWhitespaceLengthIgnoringAnsi;

    for (var item in items) {
      if (_isAnsi(item)) {
        buffer.write(item);
        continue;
      }

      for (var character in item.split('')) {
        lengthIgnoringAnsi++;
        buffer.write(character == nbsp ? ' ' : character);

        if (character == ' ') {
          lastWhitespaceIndex = buffer.length;
          lastWhitespaceLengthIgnoringAnsi = lengthIgnoringAnsi;
        }

        if (lengthIgnoringAnsi > width) {
          lastWhitespaceIndex ??= buffer.length;
          lastWhitespaceLengthIgnoringAnsi ??= lengthIgnoringAnsi;

          final bufferString = buffer.toString();
          lines.add(
            bufferString.substring(0, lastWhitespaceIndex) +
                ' ' * (width - lastWhitespaceLengthIgnoringAnsi),
          );

          buffer.clear();
          buffer.write(' ' * hangingIndent);
          buffer.write(bufferString.substring(lastWhitespaceIndex));
          lengthIgnoringAnsi =
              lengthIgnoringAnsi -
              lastWhitespaceLengthIgnoringAnsi +
              hangingIndent;

          lastWhitespaceIndex = null;
          lastWhitespaceLengthIgnoringAnsi = null;
        }
      }
    }

    if (buffer.isNotEmpty || items.isEmpty) {
      lines.add(buffer.toString() + ' ' * (width - lengthIgnoringAnsi));
    }
  }

  static String removeAnsi(String string) =>
      string.replaceAll(bold, '').replaceAll(reset, '');
}

class AnsiBufferLine {
  List<String> items;
  int indent;
  int? hangingIndent;

  AnsiBufferLine(this.items, {this.indent = 0, this.hangingIndent});
}
