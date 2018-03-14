// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:io/ansi.dart';
import 'package:logging/logging.dart';

void stdIOLogListener(LogRecord record, {bool verbose}) {
  verbose ??= false;
  final level = _levelLabel(record.level);
  final eraseLine = ansiOutputEnabled && !verbose ? '\x1b[2K\r' : '';
  var headerMessage = record.message;
  var blankLineCount = 0;
  if (headerMessage.startsWith('\n')) {
    blankLineCount =
        headerMessage.split('\n').takeWhile((line) => line.isEmpty).length;
    headerMessage = headerMessage.substring(blankLineCount);
  }
  var header = '$eraseLine$level ${_loggerName(record, verbose)}$headerMessage';
  var lines = blankLineCount > 0
      ? (new List<Object>.generate(blankLineCount, (_) => '')..add(header))
      : <Object>[header];

  if (record.error != null) {
    lines.add(record.error);
  }

  if (record.stackTrace != null && verbose) {
    lines.add(record.stackTrace);
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

String _levelLabel(Level level) => _levelColor(level).wrap(_levelName(level));

/// Reduce possible levels to the groups we care about and make sure names are 6
/// characters.
String _levelName(Level level) {
  if (level < Level.CONFIG) return '[ FINE ]';
  if (level < Level.WARNING) return '[ INFO ]';
  if (level < Level.SEVERE) return '[ WARN ]';
  return '[SEVERE]';
}

AnsiCode _levelColor(Level level) {
  if (level < Level.CONFIG) return lightBlue;
  if (level < Level.WARNING) return cyan;
  if (level < Level.SEVERE) return yellow;
  return red;
}

/// Filter out the Logger names known to come from `build_runner` and splits the
/// header for levels >= WARNING.
String _loggerName(LogRecord record, bool verbose) {
  var knownNames = const [
    'Build',
    'BuildDefinition',
    'BuildScriptUpdates',
    'CreateOutputDir',
    'Entrypoint',
    'ApplyBuilders',
    'Heartbeat',
    'Serve',
    'Watch',
    'build_runner',
  ];
  var maybeSplit = record.level >= Level.WARNING ? '\n' : '';
  return verbose || !knownNames.contains(record.loggerName)
      ? '${record.loggerName}:$maybeSplit'
      : '';
}
