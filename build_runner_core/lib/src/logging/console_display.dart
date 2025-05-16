// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

class ConsoleDisplay {
  final String Function() render;
  late final Timer timer;

  var displayedLines = 0;

  ConsoleDisplay(this.render) {
    display();
    timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      display();
    });
  }

  void display() {
    final output = render();

    final moveCursor = displayedLines == 0 ? '' : '\x1b[${displayedLines}F';
    final count = '\n'.allMatches(output).length;
    displayedLines = count;
    stdout.write('$moveCursor$output');
  }

  void dispose() {
    displayedLines = 0;
    timer.cancel();
  }
}
