// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:logging/logging.dart';

final logger = Logger.root;
final consoleLevel = Level('console', Level.ALL.value - 1);

class LogDisplay {
  final String Function() render;
  late Stopwatch stopwatch = Stopwatch()..start();

  int displayedLines = 0;
  String previousLastLine = '';
  bool closed = false;

  LogDisplay(this.render);

  void close() {
    closed = true;
  }

  void maybeDisplay() {
    if (stopwatch.elapsedMilliseconds > 100) {
      display();
    }
  }

  void display() {
    if (closed) return;
    stopwatch.reset();
    final output = render();

    final moveCursor = displayedLines == 0 ? '' : '\x1b[${displayedLines}F';
    final lines = output.split('\n');
    displayedLines = lines.length;
    logger.log(consoleLevel, '$moveCursor$output');

    final lastLine = lines.join(' ...');
    previousLastLine = lastLine;
    // TODO: split into full display and update line.
    if (lastLine != previousLastLine) {
      logger.warning(lastLine);
    }
  }

  void finish() {
    displayedLines = 0;
  }
}
