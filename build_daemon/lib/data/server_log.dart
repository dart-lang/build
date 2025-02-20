// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:logging/logging.dart' as logging;

part 'server_log.g.dart';

/// Logging levels, these have a 1:1 mapping with the levels from
/// `package:logging`.
class Level extends EnumClass implements Comparable<Level> {
  static Serializer<Level> get serializer => _$levelSerializer;

  // ignore: constant_identifier_names
  static const Level FINEST = _$finest;
  // ignore: constant_identifier_names
  static const Level FINER = _$finer;
  // ignore: constant_identifier_names
  static const Level FINE = _$fine;
  // ignore: constant_identifier_names
  static const Level CONFIG = _$config;
  // ignore: constant_identifier_names
  static const Level INFO = _$info;
  // ignore: constant_identifier_names
  static const Level WARNING = _$warning;
  // ignore: constant_identifier_names
  static const Level SEVERE = _$severe;
  // ignore: constant_identifier_names
  static const Level SHOUT = _$shout;

  const Level._(super.name);

  static BuiltSet<Level> get values => _$values;
  static Level valueOf(String name) => _$valueOf(name);

  /// Deterministic ordering for comparison.
  ///
  /// We don't want to rely on the ordering of `values` since that isn't
  /// guaranteed.
  static const _ordered = [
    FINEST,
    FINER,
    FINE,
    CONFIG,
    INFO,
    WARNING,
    SEVERE,
    SHOUT,
  ];

  @override
  int compareTo(Level other) =>
      _ordered.indexOf(this) - _ordered.indexOf(other);

  bool operator >(Level other) => compareTo(other) > 0;
  bool operator >=(Level other) => compareTo(other) >= 0;
  bool operator <(Level other) => compareTo(other) < 0;
  bool operator <=(Level other) => compareTo(other) <= 0;
}

/// Converts a [Level] to a [logging.Level].
logging.Level toLoggingLevel(Level level) => logging.Level.LEVELS.firstWhere(
  (l) => l.name == level.name,
  orElse: () => throw StateError('Unrecognized level `$level`'),
);

/// Roughly matches the `LogRecord` class from `package:logging`.
abstract class ServerLog implements Built<ServerLog, ServerLogBuilder> {
  static Serializer<ServerLog> get serializer => _$serverLogSerializer;

  factory ServerLog([void Function(ServerLogBuilder b) updates]) = _$ServerLog;

  factory ServerLog.fromLogRecord(logging.LogRecord record) => ServerLog(
    (b) =>
        b
          ..message = record.message
          ..level = Level.valueOf(record.level.name)
          ..loggerName = record.loggerName
          ..error = record.error?.toString()
          ..stackTrace = record.stackTrace?.toString(),
  );

  logging.LogRecord toLogRecord() {
    return logging.LogRecord(
      toLoggingLevel(level),
      message,
      loggerName ?? '',
      error,
      stackTrace == null ? null : StackTrace.fromString(stackTrace!),
    );
  }

  ServerLog._();

  Level get level;

  String get message;

  String? get loggerName;

  String? get error;

  String? get stackTrace;
}
