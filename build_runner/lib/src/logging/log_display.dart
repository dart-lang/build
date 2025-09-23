// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:logging/logging.dart';

import '../bootstrap/build_process_state.dart';
import 'ansi_buffer.dart';
import 'build_log.dart';
import 'build_log_messages.dart';

final _logger = Logger.root;

/// Displays log output.
///
/// Chooses the output based on `buildLog.configuration`.
///
/// For console output, counts the lines written so they can be rewritten by
/// the next output.
class LogDisplay {
  int get _displayedLines => buildProcessState.displayedLines;
  set _displayedLines(int displayedLines) =>
      buildProcessState.displayedLines = displayedLines;

  // Interrupts block output and prints [message].
  //
  // The next block output will follow below [message].
  void flushAndPrint(String message) {
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
      buildLog.configuration.forceConsoleWidthForTesting != null ||
      (buildLog.configuration.onLog == null &&
          buildLog.configuration.mode == BuildLogMode.build &&
          buildProcessState.stdio.hasTerminal &&
          buildProcessState.stdio.supportsAnsiEscapes);

  /// Displays [block] to the console.
  ///
  /// Only call this if [displayingBlocks].
  void block(AnsiBuffer block) {
    // If printOnFailure was set for running in a test, display nothing.
    if (buildLog.configuration.printOnFailure != null) {
      return;
    }

    final lines = block.lines;

    // https://en.wikipedia.org/wiki/ANSI_escape_code#:~:text=Cursor%20Previous
    // Moves cursor to the beginning of the line n lines up.
    final moveCursor = _displayedLines == 0 ? '' : '\x1b[${_displayedLines}F';
    stdout.writeln('$moveCursor${lines.join('\n')}');
    if (_displayedLines > lines.length) {
      // If the block is smaller than last time, erase the rest of the display.
      // https://en.wikipedia.org/wiki/ANSI_escape_code#:~:text=Erase%20in%20Display
      stdout.write('\x1b[J');
    }
    _displayedLines = lines.length;

    if (block.overflowsConsole) {
      flushAndPrint(
        'Log overflowed the console, switching to line-by-line logging.',
      );
      buildLog.configuration = buildLog.configuration.rebuild((b) {
        b.mode = BuildLogMode.simple;
      });
    }
  }

  /// Displays [message] with [severity].
  ///
  /// Only call this if [displayingBlocks] is `false`.
  void message(Severity severity, String message) {
    // If printOnFailure was set for running in a test, just log to that.
    if (buildLog.configuration.printOnFailure != null) {
      buildLog.configuration.printOnFailure!(
        _LogRecord(severity.toLogLevel, message, Logger.root.name).toString(),
      );
      return;
    }

    // If `onLog` is set, call it and don't do any further display.
    if (buildLog.configuration.onLog != null) {
      buildLog.configuration.onLog!(
        _LogRecord(severity.toLogLevel, message, Logger.root.name),
      );
      return;
    }

    // Log to the root logger for the benefit of any non-`build_runner` log
    // listeners.
    _logger.log(severity.toLogLevel, message);

    // Display.
    if (buildLog.configuration.mode == BuildLogMode.daemon) {
      // For `build_daemon` just display the messages, severity is determined
      // by stderr vs stdout.
      if (severity == Severity.error) {
        stderr.writeln(message);
      } else {
        stdout.writeln(message);
      }
    } else {
      stdout.writeln(_render(severity, message));
    }
  }

  String _render(Severity severity, String message) {
    final result = StringBuffer();
    var first = true;
    for (final line in message.split('\n')) {
      if (first) {
        result.write('${severity.prefix}$line');
        first = false;
      } else {
        result.write('\n  $line');
      }
    }
    return result.toString();
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
/// The logger name is always `` so there is no need to display it; use the
/// single character prefixes from [Severity] instead of the full names.
class _LogRecord extends LogRecord {
  final Severity _severity;
  _LogRecord(super.level, super.message, [super.loggerName = ''])
    : _severity = Severity.fromLogLevel(level);

  @override
  String toString() => '${_severity.prefix}$message';
}
