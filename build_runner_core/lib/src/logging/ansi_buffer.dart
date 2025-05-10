// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:collection/collection.dart';

import 'build_log.dart';

/// A buffer that wraps text taking into account ANSI escape codes.
class AnsiBuffer {
  static const String nbsp = '\u00A0';
  static const reset = '\x1B[0m';
  static const bold = '\x1B[1m';

  /// The text added to the buffer, wrapped to [width].
  final List<String> lines = [];

  /// The width that the buffer wraps to.
  int get width =>
      buildLog.configuration.forceConsoleWidthForTesting ??
      (stdout.hasTerminal ? stdout.terminalColumns : 80);

  /// Whether [lines] is taller than the console.
  bool get overflowsConsole =>
      stdout.hasTerminal && stdout.terminalLines < lines.length;

  /// Writes [items] as a line prefixed with [indent], wraps to console width;
  /// on wrapping, indents by [hangingIndent].
  ///
  /// ANSI codes must be individual items and must use the constants [reset]
  /// and/or [bold].
  ///
  /// In addition to ANSI codes, [nbsp] is a non-breaking space which will not
  /// be used for wrapping. In the buffer it is replaced with a normal space.
  void writeLine(List<String> items, {int indent = 0, int? hangingIndent}) {
    final width = this.width;
    hangingIndent ??= indent;

    final buffer = StringBuffer(' ' * indent);
    var lengthIgnoringAnsi = indent;
    int? lastWhitespaceIndex;
    int? lastWhitespaceLengthIgnoringAnsi;

    for (var item in items) {
      if (_isAnsi(item)) {
        if (_showingAnsi) {
          buffer.write(item);
        }
        continue;
      }

      for (var character in item.split('')) {
        lengthIgnoringAnsi++;
        buffer.write(character == nbsp ? ' ' : character);

        if (character == ' ') {
          lastWhitespaceIndex = buffer.length;
          lastWhitespaceLengthIgnoringAnsi = lengthIgnoringAnsi;
        }

        if (lengthIgnoringAnsi == width) {
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

  /// As [writeLine] for an [AnsiBuffer].
  void write(AnsiBufferLine line) {
    writeLine(
      line.items,
      indent: line.indent,
      hangingIndent: line.hangingIndent,
    );
  }

  /// Removes all ANSI constants from [string], for testing.
  static String removeAnsi(String string) =>
      string.replaceAll(reset, '').replaceAll(bold, '');
}

/// A line for writing to an [AnsiBuffer].
class AnsiBufferLine {
  List<String> items;
  int indent;
  int? hangingIndent;

  AnsiBufferLine(this.items, {this.indent = 0, this.hangingIndent});

  AnsiBufferLine withHangingIndent(int? hangingIndent) => AnsiBufferLine(
    items,
    indent: indent,
    hangingIndent: hangingIndent ?? this.hangingIndent,
  );

  @override
  bool operator ==(Object other) =>
      other is AnsiBufferLine &&
      indent == other.indent &&
      hangingIndent == other.hangingIndent &&
      const DeepCollectionEquality().equals(items, other.items);

  @override
  int get hashCode => throw UnimplementedError();

  @override
  String toString() {
    final result = StringBuffer();
    for (final item in items) {
      if (!_showingAnsi && _isAnsi(item)) continue;
      result.write(item);
    }
    return result.toString();
  }
}

bool _isAnsi(String item) =>
    item == AnsiBuffer.reset || item == AnsiBuffer.bold;

bool get _showingAnsi =>
    buildLog.configuration.forceAnsiConsoleForTesting ??
    (stdout.hasTerminal && stdout.supportsAnsiEscapes);
