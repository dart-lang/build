// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart';
import 'package:logging/logging.dart';

/// A delegating [Logger] that records if any logs of level >= [Level.SEVERE]
/// were seen.
class BuildForInputLogger implements Logger {
  final Logger _delegate;

  final errorsSeen = <String>[];

  BuildForInputLogger(this._delegate);

  @override
  Level get level => _delegate.level;

  @override
  set level(Level? level) => _delegate.level = level;

  @override
  Map<String, Logger> get children => _delegate.children;

  @override
  void clearListeners() => _delegate.clearListeners();

  @override
  void config(Object? message, [Object? error, StackTrace? stackTrace]) =>
      _delegate.config(message, error, stackTrace);

  @override
  void fine(Object? message, [Object? error, StackTrace? stackTrace]) =>
      _delegate.fine(message, error, stackTrace);

  @override
  void finer(Object? message, [Object? error, StackTrace? stackTrace]) =>
      _delegate.finer(message, error, stackTrace);

  @override
  void finest(Object? message, [Object? error, StackTrace? stackTrace]) =>
      _delegate.finest(message, error, stackTrace);

  @override
  String get fullName => _delegate.fullName;

  @override
  void info(Object? message, [Object? error, StackTrace? stackTrace]) =>
      _delegate.info(message, error, stackTrace);

  @override
  bool isLoggable(Level value) => _delegate.isLoggable(value);

  @override
  void log(
    Level logLevel,
    Object? message, [
    Object? error,
    StackTrace? stackTrace,
    Zone? zone,
  ]) {
    if (logLevel >= Level.SEVERE) {
      errorsSeen.add(_renderError(message, error, stackTrace));
    }
    _delegate.log(logLevel, message, error, stackTrace, zone);
  }

  @override
  String get name => _delegate.name;

  @override
  Stream<LogRecord> get onRecord => _delegate.onRecord;

  @override
  Logger? get parent => _delegate.parent;

  @override
  void severe(Object? message, [Object? error, StackTrace? stackTrace]) {
    errorsSeen.add(_renderError(message, error, stackTrace));
    _delegate.severe(message, error, stackTrace);
  }

  @override
  void shout(Object? message, [Object? error, StackTrace? stackTrace]) {
    errorsSeen.add(_renderError(message, error, stackTrace));
    _delegate.shout(message, error, stackTrace);
  }

  @override
  void warning(Object? message, [Object? error, StackTrace? stackTrace]) =>
      _delegate.warning(message, error, stackTrace);

  @override
  Stream<Level?> get onLevelChanged => _delegate.onLevelChanged;

  String _renderError(
    Object? message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    var result = message?.toString() ?? '';
    if (error != null) result += '\n$error';

    // Drop stack traces for exception types that can be caused by normal
    // user input; render stack traces for everything else as they can point to
    // bugs in generators or in build_runner.
    if (stackTrace != null &&
        error is! SyntaxErrorInAssetException &&
        error is! UnresolvableAssetException) {
      result += '\n$stackTrace';
    }
    return result;
  }
}
