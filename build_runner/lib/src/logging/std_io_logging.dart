// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:stack_trace/stack_trace.dart';

final _cyan = _isPosixTerminal ? '\u001b[36m' : '';
final _yellow = _isPosixTerminal ? '\u001b[33m' : '';
final _red = _isPosixTerminal ? '\u001b[31m' : '';
final _endColor = _isPosixTerminal ? '\u001b[0m' : '';
final _isPosixTerminal =
    !Platform.isWindows && stdioType(stdout) == StdioType.TERMINAL;

void stdIOLogListener(LogRecord record) {
  String color;
  if (record.level < Level.WARNING) {
    color = _cyan;
  } else if (record.level < Level.SEVERE) {
    color = _yellow;
  } else {
    color = _red;
  }
  var header = '${_isPosixTerminal ? '\x1b[2K\r' : ''}'
      '$color[${record.level}]$_endColor ${record.loggerName}: '
      '${record.message}';
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

  if (record.level > Level.INFO || !_isPosixTerminal || multiLine) {
    // Add an extra line to the output so the last line isn't written over.
    message.writeln('');
  }

  if (record.level >= Level.SEVERE) {
    stderr.write(message);
  } else {
    stdout.write(message);
  }
}
