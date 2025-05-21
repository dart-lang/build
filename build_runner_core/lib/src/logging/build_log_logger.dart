// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart';
import 'package:logging/logging.dart';

import 'build_log.dart';

final _log = BuildLog();

/// A [Logger] that forwards messages to [BuildLog] and records errors.
class BuildLogLogger implements Logger {
  final String? stage;
  final String? note;
  final List<String> errors = [];

  BuildLogLogger({this.stage, this.note});

  @override
  Level get level => Level.INFO;

  @override
  set level(Level? value) {}

  @override
  Map<String, Logger> get children => {};

  @override
  void clearListeners() {}

  @override
  String get fullName => throw UnimplementedError();

  @override
  bool isLoggable(Level value) => true;

  @override
  void log(
    Level logLevel,
    Object? message, [
    Object? error,
    StackTrace? stackTrace,
    Zone? zone,
  ]) {
    final renderedMessage = _render(message, error, stackTrace);

    if (logLevel < Level.INFO) {
      _log.fine(renderedMessage);
    } else if (logLevel < Level.WARNING) {
      _log.info(renderedMessage);
    } else if (logLevel < Level.SEVERE) {
      _log.warning(renderedMessage);
    } else {
      errors.add(renderedMessage);
      _log.severe(renderedMessage);
    }
  }

  String _render(Object? message, [Object? error, StackTrace? stackTrace]) {
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

  @override
  // TODO: implement name
  String get name => throw UnimplementedError();

  @override
  // TODO: implement onLevelChanged
  Stream<Level?> get onLevelChanged => throw UnimplementedError();

  @override
  // TODO: implement onRecord
  Stream<LogRecord> get onRecord => throw UnimplementedError();

  @override
  // TODO: implement parent
  Logger? get parent => throw UnimplementedError();

  @override
  void finest(Object? message, [Object? error, StackTrace? stackTrace]) =>
      log(Level.FINEST, message, error, stackTrace);

  @override
  void finer(Object? message, [Object? error, StackTrace? stackTrace]) =>
      log(Level.FINER, message, error, stackTrace);

  @override
  void fine(Object? message, [Object? error, StackTrace? stackTrace]) =>
      log(Level.FINE, message, error, stackTrace);

  @override
  void config(Object? message, [Object? error, StackTrace? stackTrace]) =>
      log(Level.CONFIG, message, error, stackTrace);

  @override
  void info(Object? message, [Object? error, StackTrace? stackTrace]) =>
      log(Level.INFO, message, error, stackTrace);

  @override
  void warning(Object? message, [Object? error, StackTrace? stackTrace]) =>
      log(Level.WARNING, message, error, stackTrace);

  @override
  void severe(Object? message, [Object? error, StackTrace? stackTrace]) =>
      log(Level.SEVERE, message, error, stackTrace);

  @override
  void shout(Object? message, [Object? error, StackTrace? stackTrace]) =>
      log(Level.SHOUT, message, error, stackTrace);
}
