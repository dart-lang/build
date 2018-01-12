// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';

import 'human_readable_duration.dart';

// Ensures on windows this message does not get overwritten by later logs.
final _logSuffix = '${Platform.isWindows ? '' : '\n'}';

/// Logs an asynchronous [action] with [description] before and after.
///
/// Returns a future that completes after the action and logging finishes.
Future<T> logTimedAsync<T>(
  Logger logger,
  String description,
  Future<T> action(), {
  Level level: Level.INFO,
}) async {
  final watch = new Stopwatch()..start();
  logger.log(level, '$description...');
  final result = await action();
  watch.stop();
  final time = '${humanReadable(watch.elapsed)}$_logSuffix';
  logger.log(level, '$description completed, took $time');
  return result;
}

/// Logs a synchronous [action] with [description] before and after.
///
/// Returns a future that completes after the action and logging finishes.
T logTimedSync<T>(
  Logger logger,
  String description,
  T action(), {
  Level level: Level.INFO,
}) {
  final watch = new Stopwatch()..start();
  logger.log(level, '$description...');
  final result = action();
  watch.stop();
  final time = '${humanReadable(watch.elapsed)}$_logSuffix';
  logger.log(level, '$description completed, took $time');
  return result;
}
