// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:logging/logging.dart';

final logger = Logger.root;
final consoleLevel = Level('console', Level.ALL.value + 1);

class LogDisplay {
  late Stopwatch stopwatch = Stopwatch()..start();

  int displayedLines = 0;
  String previousLastLine = '';
  bool closed = false;

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

    final moveCursor = displayedLines == 0 ? '' : '\x1b[${displayedLines}F';
    displayedLines = entry.lines.length;

    logger.log(consoleLevel, '$moveCursor${entry.block}');
    logger.log(entry.level, entry.line);
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

  String get block => lines.map((l) => '$l\n').join('');

  Level get level => switch (severity) {
    LineSeverity.info => Level.INFO,
    LineSeverity.warning => Level.WARNING,
    LineSeverity.error => Level.SEVERE,
  };
}

enum LineSeverity { info, warning, error }
