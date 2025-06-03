// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class AnsiBuffer {
  static const String reset = '\x1B[0m';
  static const String bold = '\x1B[1m';
  static const String red = '\x1B[31m';
  static const String green = '\x1B[32m';

  final int width = 80;
  final List<String> lines = [];

  bool _isAnsi(String item) =>
      item == reset || item == bold || item == red || item == green;

  void writeLine(List<String> items, {int indent = 0}) {
    final buffer = StringBuffer(' ' * indent);
    var lengthIgnoringAnsi = indent;
    int? lastWhitespaceIndex;
    int? lastWhitespaceLengthIgnoringAnsi;

    for (var item in items) {
      if (_isAnsi(item)) {
        buffer.write(item);
        continue;
      }

      for (final character in item.split('')) {
        lengthIgnoringAnsi++;
        buffer.write(character);

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
          buffer.write(' ' * indent);
          buffer.write(bufferString.substring(lastWhitespaceIndex));
          lengthIgnoringAnsi =
              lengthIgnoringAnsi - lastWhitespaceLengthIgnoringAnsi + indent;

          lastWhitespaceIndex = null;
          lastWhitespaceLengthIgnoringAnsi = null;
        }
      }
    }

    if (buffer.isNotEmpty) {
      lines.add(buffer.toString() + ' ' * (width - lengthIgnoringAnsi));
    }
  }

  static String removeAnsi(String string) =>
      string.replaceAll(bold, '').replaceAll(reset, '');
}
