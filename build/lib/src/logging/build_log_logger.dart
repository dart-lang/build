// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

// ignore: implementation_imports
import 'package:build/src/internal.dart';
import 'package:logging/logging.dart';

import 'build_log.dart';
import 'build_log_messages.dart';

/// [Logger] that forwards messages to [BuildLog] and records errors.
///
/// Use `buildLog.loggerForPhase` or `buildLog.loggerForOther` to create an
/// instance.
///
/// Then use [scopeLogAsync] or [scopeLogSync] to run builder code while
/// redirecting prints and exception logs to `buildLog` via the
/// `BuildLogLogger`.
///
/// Messages of level lower than `WARNING` are logged only in verbose mode,
/// according to `buildLog.configuration.verbose`.
///
/// Messages at level `SEVERE` and higher are stored in [errors] as well as
/// displayed via `buildLog`.
class BuildLogLogger implements Logger {
  final String? phaseName;
  final String? context;

  /// The errors logged to this logger.
  final List<String> errors = [];

  BuildLogLogger({this.phaseName, this.context});

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
        log.severe(null, e, st);
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
        log.severe(null, e, st);
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
  Level get level => buildLog.configuration.verbose ? Level.ALL : Level.WARNING;

  @override
  set level(Level? value) =>
      throw UnsupportedError('Builders are not allowed to set loggel level.');

  @override
  Map<String, Logger> get children => const {};

  @override
  void clearListeners() {}

  @override
  String get fullName => name;

  @override
  bool isLoggable(Level value) =>
      value >= Level.WARNING || buildLog.configuration.verbose;

  @override
  void log(
    Level logLevel,
    Object? message, [
    Object? error,
    StackTrace? stackTrace,
    Zone? zone,
  ]) {
    if (!isLoggable(logLevel)) return;
    final renderedMessage = buildLog.renderThrowable(
      message,
      error,
      stackTrace,
    );
    if (logLevel >= Level.SEVERE) errors.add(renderedMessage);
    buildLog.fromBuildLogLogger(
      severity: Severity.fromLogLevel(logLevel),
      phaseName: phaseName,
      context: context,
      renderedMessage,
    );
  }

  @override
  String get name => phaseName ?? '';

  @override
  Stream<Level?> get onLevelChanged =>
      throw UnsupportedError(
        'Builders are not allowed to subscribe to logger level changes.',
      );

  @override
  Stream<LogRecord> get onRecord =>
      throw UnsupportedError(
        'Builders are not allowed to subscribe to log records.',
      );

  @override
  Logger? get parent => null;

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
