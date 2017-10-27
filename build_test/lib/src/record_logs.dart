// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/src/builder/logging.dart';
import 'package:matcher/matcher.dart';
import 'package:logging/logging.dart';

/// Executes [run] with a new [Logger], returning the resulting log records.
///
/// The returned [Stream] is _closed_ after the [run] function is executed. If
/// [run] returns a [Future], that future is awaited _before_ the stream is
/// closed.
///
/// ```dart
/// test('should log "uh oh!"', () async {
///   final logs = recordLogs(() => runBuilder());
///   expect(logs, emitsInOrder([
///     anyLogOf('uh oh!'),
///   ]);
/// });
/// ```
Stream<LogRecord> recordLogs(dynamic run(), {String name: ''}) {
  final logger = new Logger(name);
  Timer.run(() async {
    await scopeLogAsync(() => new Future.value(run()), logger);
    logger.clearListeners();
  });
  return logger.onRecord;
}

/// Matches [LogRecord] of any level whose message is [messageOrMatcher].
///
/// ```dart
/// anyLogOf('Hello World)';     // Exactly match 'Hello World'.
/// anyLogOf(contains('ERROR')); // Contains the sub-string 'ERROR'.
/// ```
Matcher anyLogOf(dynamic messageOrMatcher) =>
    new _LogRecordMatcher(anything, messageOrMatcher);

/// Matches [LogRecord] of [Level.INFO] where message is [messageOrMatcher].
Matcher infoLogOf(dynamic messageOrMatcher) =>
    new _LogRecordMatcher(Level.INFO, messageOrMatcher);

/// Matches [LogRecord] of [Level.WARNING] where message is [messageOrMatcher].
Matcher warningLogOf(dynamic messageOrMatcher) =>
    new _LogRecordMatcher(Level.WARNING, messageOrMatcher);

/// Matches [LogRecord] of [Level.SEVERE] where message is [messageOrMatcher].
Matcher severeLogOf(dynamic messageOrMatcher) =>
    new _LogRecordMatcher(Level.SEVERE, messageOrMatcher);

class _LogRecordMatcher extends Matcher {
  final Matcher _level;
  final Matcher _message;

  factory _LogRecordMatcher(dynamic levelOr, dynamic messageOr) =>
      new _LogRecordMatcher._(levelOr is Matcher ? levelOr : equals(levelOr),
          messageOr is Matcher ? messageOr : equals(messageOr));

  _LogRecordMatcher._(this._level, this._message);

  @override
  Description describe(Description description) {
    description.add('level: ');
    _level.describe(description);
    description.add(', message: ');
    _message.describe(description);
    return description;
  }

  @override
  Description describeMismatch(
      covariant LogRecord item, Description description, _, __) {
    if (!_level.matches(item.level, {})) {
      _level.describeMismatch(item.level, description, {}, false);
    }
    if (!_message.matches(item.message, {})) {
      _message.describeMismatch(item.message, description, {}, false);
    }
    return description;
  }

  @override
  bool matches(item, _) =>
      item is LogRecord &&
      _level.matches(item.level, {}) &&
      _message.matches(item.message, {});
}
