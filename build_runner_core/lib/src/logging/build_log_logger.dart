// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

// ignore: implementation_imports
import 'package:build/src/internal.dart';
import 'package:logging/logging.dart';

import 'build_log.dart';

/// A [Logger] that forwards messages to [BuildLog] and records errors.
///
/// Use [scopeLogAsync] or [scopeLogSync] to run builder code while redirecting
/// prints and exception logs to a `BuildLogLogger`.
class BuildLogLogger implements Logger {
  final String? stage;
  final String? note;
  final List<String> errors = [];

  BuildLogLogger({this.stage, this.note});

  /// Runs [fn] in an error handling [Zone].
  ///
  /// Any calls to [print] will be logged with `log.warning`, and any errors
  /// will be logged with `log.severe`.
  ///
  /// Completes with the first error or result of `fn`, whichever comes first.
  static Future<T> scopeLogAsync<T>(Future<T> Function() fn, Logger log) {
    var done = Completer<T>();
    runZonedGuarded(
      fn,
      (e, st) {
        log.severe('', e, st);
        if (done.isCompleted) return;
        done.completeError(e, st);
      },
      zoneSpecification: ZoneSpecification(
        print: (self, parent, zone, message) {
          log.warning(message);
        },
      ),
      zoneValues: {logKey: log},
    )?.then((result) {
      if (done.isCompleted) return;
      done.complete(result);
    });
    return done.future;
  }

  /// Runs [fn] in an error handling [Zone].
  ///
  /// Any calls to [print] will be logged with `log.info`, and any errors will
  /// be logged with `log.severe`.
  static T? scopeLogSync<T>(T Function() fn, Logger log) {
    return runZonedGuarded(
      fn,
      (e, st) {
        log.severe('', e, st);
      },
      zoneSpecification: ZoneSpecification(
        print: (self, parent, zone, message) {
          log.info(message);
        },
      ),
      zoneValues: {logKey: log},
    );
  }

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
    final renderedMessage = buildLog.renderThrowable(
      message,
      error,
      stackTrace,
    );

    if (logLevel < Level.WARNING) {
      buildLog.info(renderedMessage, stage: stage, note: note);
    } else if (logLevel < Level.SEVERE) {
      buildLog.warning(renderedMessage, stage: stage, note: note);
    } else {
      errors.add(renderedMessage);
      buildLog.severe(renderedMessage, stage: stage, note: note);
    }
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
