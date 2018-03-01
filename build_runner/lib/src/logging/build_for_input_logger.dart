// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:logging/logging.dart';

/// A delegating [Logger] that records if any logs of level >= [Level.SEVERE]
/// were seen.
class BuildForInputLogger implements Logger {
  final Logger _delegate;

  bool _errorWasSeen = false;
  bool get errorWasSeen => _errorWasSeen;

  BuildForInputLogger(this._delegate);

  @override
  Level get level => _delegate.level;

  @override
  set level(Level level) => _delegate.level = level;

  @override
  Map<String, Logger> get children => _delegate.children;

  @override
  void clearListeners() => _delegate.clearListeners();

  @override
  void config(message, [Object error, StackTrace stackTrace]) =>
      _delegate.config(message, error, stackTrace);

  @override
  void fine(message, [Object error, StackTrace stackTrace]) =>
      _delegate.fine(message, error, stackTrace);

  @override
  void finer(message, [Object error, StackTrace stackTrace]) =>
      _delegate.finer(message, error, stackTrace);

  @override
  void finest(message, [Object error, StackTrace stackTrace]) =>
      _delegate.finest(message, error, stackTrace);

  @override
  String get fullName => _delegate.fullName;

  @override
  void info(message, [Object error, StackTrace stackTrace]) =>
      _delegate.info(message, error, stackTrace);

  @override
  bool isLoggable(Level value) => _delegate.isLoggable(value);

  @override
  void log(Level logLevel, message,
      [Object error, StackTrace stackTrace, Zone zone]) {
    if (logLevel >= Level.SEVERE) {
      _errorWasSeen = true;
    }
    if (logLevel >= Level.WARNING) {
      if (_delegate.isLoggable(logLevel)) {
        var original = message;
        if (message is Function) message = () => '\n${original()}';
        if (message is String) {
          message = '\n$message';
        }
      }
    }
    _delegate.log(logLevel, message, error, stackTrace, zone);
  }

  @override
  String get name => _delegate.name;

  @override
  Stream<LogRecord> get onRecord => _delegate.onRecord;

  @override
  Logger get parent => _delegate.parent;

  @override
  void severe(message, [Object error, StackTrace stackTrace]) {
    _errorWasSeen = true;
    _delegate.severe(message, error, stackTrace);
  }

  @override
  void shout(message, [Object error, StackTrace stackTrace]) {
    _errorWasSeen = true;
    _delegate.shout(message, error, stackTrace);
  }

  @override
  void warning(message, [Object error, StackTrace stackTrace]) =>
      _delegate.warning(message, error, stackTrace);
}
