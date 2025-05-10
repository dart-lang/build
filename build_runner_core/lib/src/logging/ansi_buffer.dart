// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class AnsiBuffer {
  static const String bold = '\x1B[1m';
  static const String reset = '\x1B[0m';

  final int width = 80;
  final List<String> lines = [];

  bool _isAnsi(String item) => item == bold || item == reset;

  void writeLine(List<String> items, {int indent = 0}) {
    final buffer = StringBuffer();
    var lengthIgnoringAnsi = 0;
    for (final item in items) {
      if (!_isAnsi(item)) lengthIgnoringAnsi += item.length;
      buffer.write(item);
      if (lengthIgnoringAnsi > width) {
        final string = buffer.toString();
        final index = string.length - (lengthIgnoringAnsi - width);
        lines.add(string.substring(0, index));
        final overflow = string.substring(index);
        buffer.clear();
        buffer.write(' ' * indent);
        buffer.write(overflow);
        lengthIgnoringAnsi = indent + overflow.length;
      }
    }
    if (buffer.isNotEmpty) {
      lines.add(buffer.toString() + ' ' * (width - lengthIgnoringAnsi));
    }
  }

  static String removeAnsi(String string) =>
      string.replaceAll(bold, '').replaceAll(reset, '');
}
