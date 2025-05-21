// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:logging/logging.dart';

final logger = Logger.root;

class LogDisplay {
  late Stopwatch stopwatch = Stopwatch()..start();

  int displayedLines = 0;
  String previousLastLine = '';
  bool closed = false;
  void Function(LogRecord record)? onLog;

  void close() {
    closed = true;
  }

  void maybeDisplay(BuildLogEntry Function() render) {
    if (stopwatch.elapsedMilliseconds > 100) {
      display(render());
    }
  }

  void display(BuildLogEntry entry) {
    if (closed) return;
    stopwatch.reset();

    if (onLog != null) {
      onLog!(LogRecord(entry.level, entry.line, ''));
      return;
    }

    logger.log(entry.level, entry.line);
    if (stdout.hasTerminal && stdout.supportsAnsiEscapes) {
      final moveCursor = displayedLines == 0 ? '' : '\x1b[${displayedLines}F';
      displayedLines = entry.lines.length;

      stdout.writeln('$moveCursor${entry.block}');
    } else {
      stdout.writeln(entry.line);
      /*if (entry.severity == LineSeverity.error) {
        stderr.writeln(entry.line);
      } else {
        stdout.writeln(entry.line);
      }*/
    }
  }

  void finish() {
    displayedLines = 0;
  }
}

class BuildLogEntry {
  final List<String> lines;
  final String line;
  final LineSeverity severity;

  BuildLogEntry({
    required this.lines,
    required this.line,
    required this.severity,
  });

  String get block => lines.join('\n');

  Level get level => switch (severity) {
    LineSeverity.fine => Level.FINE,
    LineSeverity.info => Level.INFO,
    LineSeverity.warning => Level.WARNING,
    LineSeverity.error => Level.SEVERE,
  };
}

enum LineSeverity { fine, info, warning, error }
