// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:stack_trace/stack_trace.dart';

/// A handle on a [Logger] which writes logs to an [IOSink] incrementally.
///
/// LogRecords will print to stderr if the message is logged at a level >=
/// `printLevel`.
///
/// This logger must be closed after use in order to close files properly.
class IOSinkLogHandle {
  final Logger logger;
  final IOSink _outSink;

  /// All the messages printed to the IOSink.
  final List<String> printedMessages;

  StreamSubscription _logSubscription;

  int _warningCount = 0;
  int get warningCount => _warningCount;
  int _errorCount = 0;
  int get errorCount => _errorCount;

  IOSinkLogHandle(IOSink ioSink, {Level printLevel, bool printToStdErr: true})
      : _outSink = ioSink,
        logger = _createLogger(),
        printedMessages = <String>[] {
    _logSubscription = logger.onRecord.listen((logRecord) {
      var level = logRecord.level;
      var message = logRecord.message;
      // TODO; Come up with a real fix for this. The Resolver from code
      // transformers logs errors on missing files, but we don't really want to
      // error in that case, especially for generated files. For now we just
      // lower these to info messages.
      if (_missingFileError(message) && level >= Level.WARNING) {
        level = message.contains('.g.dart') ? Level.INFO : Level.WARNING;
      }
      var logMessage = _logMessage(logRecord);
      // Always write to the sink before stderr.
      ioSink.writeln(logMessage);

      if (level == Level.WARNING) {
        _warningCount++;
      }
      if (level == Level.SEVERE || level == Level.SHOUT) {
        _errorCount++;
      }
      // Optionally write to stderr.
      if (_shouldLog(level, printLevel)) {
        if (printToStdErr) stderr.writeln(logMessage);
        printedMessages.add(logMessage);
      }
    });
  }

  factory IOSinkLogHandle.toFile(String logFile,
          {Level printLevel, bool printToStdErr: true}) =>
      new IOSinkLogHandle(new File(logFile).openWrite(),
          printLevel: printLevel, printToStdErr: printToStdErr);

  /// Must be called to finish writing logs.
  Future close() async {
    await _logSubscription.cancel();
    await _outSink.flush();
    await _outSink.close();
  }
}

Logger _createLogger() {
  hierarchicalLoggingEnabled = true;
  return new Logger.detached('codegen')..level = Level.ALL;
}

String _logMessage(LogRecord record) {
  var buffer = new StringBuffer('[${record.level}]: ${record.message}');
  if (record.error != null) buffer.write('\n${record.error}');
  if (record.stackTrace != null) {
    buffer.write('\n${new Chain.forTrace(record.stackTrace).terse}');
  }
  return buffer.toString();
}

/// Checks if actualLevel >= minLevel
bool _shouldLog(Level actualLevel, Level minLevel) {
  if (minLevel == null) return false;
  return actualLevel.compareTo(minLevel) >= 0;
}

// Detect errors about missing files from the resolver.
bool _missingFileError(String message) =>
    message.startsWith('Could not load asset') ||
    message.startsWith('Missing "part ');
