// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

class LogDisplay {
  final String Function() render;
  late Stopwatch stopwatch = Stopwatch()..start();

  int displayedLines = 0;
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
    final count = '\n'.allMatches(output).length;
    displayedLines = count;
    stdout.write('$moveCursor$output');
  }

  void finish() {
    displayedLines = 0;
  }
}
