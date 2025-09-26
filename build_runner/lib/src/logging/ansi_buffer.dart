// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math';

import 'package:collection/collection.dart';

import '../bootstrap/build_process_state.dart';
import 'build_log.dart';

/// A buffer that wraps text taking into account ANSI escape codes.
class AnsiBuffer {
  static const String nbsp = '\u00A0';
  static const reset = '\x1B[0m';
  static const bold = '\x1B[1m';
  static const boldRed = '\x1B[1;31m';
  static const _nbspCodeUnit = 0xA0;
  static const _spaceCodeUnit = 32;

  /// The text added to the buffer, wrapped to [width].
  final List<String> lines = [];

  /// The width that the buffer wraps to.
  static int get width =>
      buildLog.configuration.forceConsoleWidthForTesting ??
      (buildProcessState.stdio.hasTerminal
          ? buildProcessState.stdio.terminalColumns
          : 80);

  /// Whether [lines] is taller than the console.
  bool get overflowsConsole =>
      buildProcessState.stdio.hasTerminal &&
      buildProcessState.stdio.terminalLines < lines.length;

  /// Writes [items] as a line prefixed with [indent], wraps to console width;
  /// on wrapping, indents by [hangingIndent].
  ///
  /// Indent and hanging indent are capped at `width ~/ 2`.
  ///
  /// ANSI codes must be individual items and must use the constants [reset]
  /// and/or [bold].
  ///
  /// In addition to ANSI codes, [nbsp] is a non-breaking space which will not
  /// be used for wrapping. In the buffer it is replaced with a normal space.
  void writeLine(List<String> items, {int indent = 0, int? hangingIndent}) {
    final width = AnsiBuffer.width;
    hangingIndent ??= indent;
    indent = min(indent, width ~/ 2);
    hangingIndent = min(hangingIndent, width ~/ 2);

    final buffer = StringBuffer(' ' * indent);
    var lengthIgnoringAnsi = indent;
    int? lastWhitespaceIndex;
    int? lastWhitespaceLengthIgnoringAnsi;

    for (final item in items) {
      if (_isAnsi(item)) {
        if (_showingAnsi) {
          buffer.write(item);
        }
        continue;
      }

      for (final character in item.codeUnits) {
        lengthIgnoringAnsi++;
        buffer.writeCharCode(
          character == _nbspCodeUnit ? _spaceCodeUnit : character,
        );

        if (character == _spaceCodeUnit) {
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
          // There can be no ANSI codes in the overflow.
          lengthIgnoringAnsi = buffer.length;

          // If hangingIndent > indent then the overflow from the first line
          // can fill line two and spill onto line three.
          if (buffer.length >= width) {
            final bufferString = buffer.toString();
            final overflow = bufferString.substring(width);
            lines.add(bufferString.substring(0, width));
            buffer.clear();
            buffer.write(' ' * hangingIndent);
            buffer.write(overflow);
            lengthIgnoringAnsi = buffer.length;
          }

          lastWhitespaceIndex = null;
          lastWhitespaceLengthIgnoringAnsi = null;
        }
      }
    }

    final bufferString = buffer.toString();
    // Handle cases where the buffer is just indent or hanging indent.
    final bufferHasContent = bufferString.codeUnits.any(
      (c) => c != _spaceCodeUnit,
    );
    // Always write if `items.isEmpty` so `writeLine([])` writes an empty line.
    if (bufferHasContent || items.isEmpty) {
      lines.add(bufferString + ' ' * (width - lengthIgnoringAnsi));
    }
  }

  void writeEmptyLine() => writeLine([]);

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
      string.replaceAll(reset, '').replaceAll(bold, '').replaceAll(boldRed, '');
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

  // Package-private class that is never hashed.
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
    item == AnsiBuffer.reset ||
    item == AnsiBuffer.bold ||
    item == AnsiBuffer.boldRed;

bool get _showingAnsi =>
    buildLog.configuration.forceAnsiConsoleForTesting ??
    (buildProcessState.stdio.hasTerminal &&
        buildProcessState.stdio.supportsAnsiEscapes);
