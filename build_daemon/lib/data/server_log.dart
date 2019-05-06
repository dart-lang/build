// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:logging/logging.dart' as logging;

part 'server_log.g.dart';

enum Level {
  finest,
  finer,
  fine,
  config,
  info,
  warning,
  severe,
  shout,
}

/// Converts a [logging.Level] to a [Level].
///
/// Throws an [ArgumentError] if the [level] is not one of
/// [logging.Level.LEVELS].
Level fromLoggingLevel(logging.Level level) {
  if (level == logging.Level.FINEST) {
    return Level.finest;
  } else if (level == logging.Level.FINER) {
    return Level.finer;
  } else if (level == logging.Level.FINE) {
    return Level.fine;
  } else if (level == logging.Level.CONFIG) {
    return Level.config;
  } else if (level == logging.Level.INFO) {
    return Level.info;
  } else if (level == logging.Level.WARNING) {
    return Level.warning;
  } else if (level == logging.Level.SEVERE) {
    return Level.severe;
  } else if (level == logging.Level.SHOUT) {
    return Level.shout;
  }
  throw ArgumentError.value(
      level, 'level', 'Must be one of [Level.LEVELS] from package:logging');
}

/// Converts a [Level] to a [logging.Level].
logging.Level toLoggingLevel(Level level) {
  switch (level) {
    case Level.finest:
      return logging.Level.FINEST;
    case Level.finer:
      return logging.Level.FINER;
    case Level.fine:
      return logging.Level.FINE;
    case Level.config:
      return logging.Level.CONFIG;
    case Level.info:
      return logging.Level.INFO;
    case Level.warning:
      return logging.Level.WARNING;
    case Level.severe:
      return logging.Level.SEVERE;
    case Level.shout:
      return logging.Level.SHOUT;
  }
  throw StateError('Unrecognized level $level');
}

/// Roughly matches the `LogRecord` class from `package:logging`.
abstract class ServerLog implements Built<ServerLog, ServerLogBuilder> {
  static Serializer<ServerLog> get serializer => _$serverLogSerializer;

  factory ServerLog([updates(ServerLogBuilder b)]) = _$ServerLog;

  factory ServerLog.fromLogRecord(logging.LogRecord record) =>
      ServerLog((b) => b
        ..message = record.message
        ..level = fromLoggingLevel(record.level)
        ..loggerName = record.loggerName
        ..error = record?.error?.toString()
        ..stackTrace =
            record.stackTrace == null ? null : record.stackTrace.toString());

  logging.LogRecord toLogRecord() {
    return logging.LogRecord(toLoggingLevel(level), message, loggerName ?? '',
        error, stackTrace == null ? null : StackTrace.fromString(stackTrace));
  }

  ServerLog._();

  Level get level;

  String get message;

  @nullable
  String get loggerName;

  @nullable
  String get error;

  @nullable
  String get stackTrace;
}
