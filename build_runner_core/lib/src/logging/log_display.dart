// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

// ignore: implementation_imports
import 'package:build_runner/src/internal.dart';
import 'package:logging/logging.dart';

import 'build_log.dart';
import 'build_log_messages.dart';

final _logger = Logger.root;

class LogDisplay {
  String previousLastLine = '';

  int get _displayedLines => buildProcessState.displayedLines;
  set _displayedLines(int displayedLines) =>
      buildProcessState.displayedLines = displayedLines;

  void prompt(String message) {
    _displayedLines = 0;
    if (buildLog.configuration.onLog != null) {
      buildLog.configuration.onLog!(
        _LogRecord(Level.INFO, message, Logger.root.name),
      );
      return;
    }
    stdout.writeln(message);
  }

  /// Whether blocks are displayed.
  ///
  /// Otherwise, messages are displayed or sent to `onLog` line by line.
  bool get displayingBlocks =>
      buildLog.configuration.onLog == null &&
      buildLog.configuration.mode == BuildLogMode.build &&
      stdout.hasTerminal &&
      stdout.supportsAnsiEscapes;

  void block(List<String> lines) {
    if (!displayingBlocks) return;
    final moveCursor = _displayedLines == 0 ? '' : '\x1b[${_displayedLines}F';
    _displayedLines = lines.length;
    stdout.writeln('$moveCursor${lines.join('\n')}');
  }

  void message(BuildLogSeverity severity, String message) {
    // If block display is possible it replaces message display.
    if (displayingBlocks) return;

    // If `onLog` is set, call it and don't do any further display.
    if (buildLog.configuration.onLog != null) {
      buildLog.configuration.onLog!(
        _LogRecord(severity.level, message, Logger.root.name),
      );
      return;
    }

    // Log to the root logger for the benefit of any non-`build_runner` log
    // listeners.
    _logger.log(severity.level, message);

    // Display.
    if (buildLog.configuration.mode == BuildLogMode.daemon &&
        severity == BuildLogSeverity.error) {
      stderr.writeln(severity.render(message));
    } else {
      stdout.writeln(severity.render(message));
    }
  }

  /// If [displayingBlocks], stops updating the current block and starts a new
  /// one.
  ///
  /// Otherwise, does nothing.
  void flush() {
    _displayedLines = 0;
  }
}

/// As [LogRecord] with better `toString`.
///
/// The logger name is always `` so there is no need to display it.
class _LogRecord extends LogRecord {
  _LogRecord(super.level, super.message, [super.loggerName = '']);

  @override
  String toString() => '$level: $message';
}
