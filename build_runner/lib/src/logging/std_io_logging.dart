// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:io/ansi.dart';
import 'package:logging/logging.dart';
import 'package:stack_trace/stack_trace.dart';

void stdIOLogListener(LogRecord record, {bool verbose}) {
  verbose ??= false;
  AnsiCode color;
  if (record.level < Level.WARNING) {
    color = cyan;
  } else if (record.level < Level.SEVERE) {
    color = yellow;
  } else {
    color = red;
  }
  final level = color.wrap('[${record.level}]');
  final eraseLine = ansiOutputEnabled && !verbose ? '\x1b[2K\r' : '';
  var header = '$eraseLine$level ${record.loggerName}: ${record.message}';
  var lines = <Object>[header];

  if (record.error != null) {
    lines.add(record.error);
  }

  if (record.stackTrace != null) {
    if (record.stackTrace is Trace) {
      lines.add((record.stackTrace as Trace).terse);
    } else {
      lines.add(record.stackTrace);
    }
  }

  var message = new StringBuffer(lines.join('\n'));

  // We always add an extra newline at the end of each message, so it
  // isn't multiline unless we see > 2 lines.
  var multiLine = LineSplitter.split(message.toString()).length > 2;

  if (record.level > Level.INFO || !ansiOutputEnabled || multiLine || verbose) {
    // Add an extra line to the output so the last line isn't written over.
    message.writeln('');
  }

  if (record.level >= Level.SEVERE) {
    stderr.write(message);
  } else {
    stdout.write(message);
  }
}
