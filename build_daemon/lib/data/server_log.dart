// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:logging/logging.dart';

part 'server_log.g.dart';

/// Roughly matches the `LogRecord` class from `package:logging`.
abstract class ServerLog implements Built<ServerLog, ServerLogBuilder> {
  static Serializer<ServerLog> get serializer => _$serverLogSerializer;

  factory ServerLog([updates(ServerLogBuilder b)]) = _$ServerLog;

  factory ServerLog.fromLogRecord(LogRecord record) => ServerLog((b) => b
    ..message = record.message
    ..level = record.level.value
    ..loggerName = record.loggerName
    ..error = record?.error?.toString()
    ..stackTrace =
        record.stackTrace == null ? null : record.stackTrace.toString());

  LogRecord toLogRecord() {
    var logLevel = Level.LEVELS.firstWhere((l) => l.value == level,
        orElse: () => throw ArgumentError.value(
            level,
            'level',
            'Only pre-defined log levels are supported, see [Level.LEVELS] '
                'from package:logging.'));
    return LogRecord(logLevel, message, loggerName ?? '', error,
        stackTrace == null ? null : StackTrace.fromString(stackTrace));
  }

  ServerLog._();

  int get level;

  String get message;

  @nullable
  String get loggerName;

  @nullable
  String get error;

  @nullable
  String get stackTrace;
}
