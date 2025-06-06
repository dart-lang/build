// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

// ignore: implementation_imports
import 'package:build_runner/src/build_script_generate/build_process_state.dart';
import 'package:logging/logging.dart';

final logger = Logger.root;

class LogDisplay {
  late Stopwatch stopwatch = Stopwatch()..start();

  bool severeToStderr = false;

  String previousLastLine = '';
  bool closed = false;
  void Function(LogRecord record)? onLog;

  void close() {
    closed = true;
  }

  int get displayedLines => buildProcessState.displayedLines;
  set displayedLines(int displayedLines) =>
      buildProcessState.displayedLines = displayedLines;

  void prompt(String message) {
    displayedLines = 0;
    if (onLog != null) {
      onLog!(_LogRecord(Level.INFO, message, Logger.root.name));
      return;
    }
    stdout.writeln(message);
  }

  void display(BuildLogEntry entry, {bool force = false}) {
    if (closed) return;
    stopwatch.reset();

    if (onLog != null) {
      onLog!(_LogRecord(entry.level, entry.message, Logger.root.name));
      return;
    }

    logger.log(entry.level, entry.message);
    if (stdout.hasTerminal && stdout.supportsAnsiEscapes) {
      // TODO throttle / force
      final moveCursor = displayedLines == 0 ? '' : '\x1b[${displayedLines}F';
      displayedLines = entry.lines.length;

      stdout.writeln('$moveCursor${entry.block}');
    } else {
      if (severeToStderr && entry.severity == LineSeverity.error) {
        stderr.writeln(entry.message);
      } else {
        if (force || entry.message != previousLastLine) {
          stdout.writeln(entry.message);
        }
        previousLastLine = entry.message;
      }
    }
  }

  void finish() {
    displayedLines = 0;
  }
}

class BuildLogEntry {
  final List<String> lines;
  final String message;
  final LineSeverity severity;

  BuildLogEntry({
    required this.lines,
    required this.message,
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

/// As [LogRecord] with better `toString`.
///
/// The logger name is always `` so there is no need to display it.
class _LogRecord extends LogRecord {
  _LogRecord(super.level, super.message, [super.loggerName = '']);

  @override
  String toString() => '$level: $message';
}
