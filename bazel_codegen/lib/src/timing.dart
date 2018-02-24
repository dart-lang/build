// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';

import 'package:logging/logging.dart';

/// Tracks timing related to codegen actions.
class CodegenTiming {
  static const _mainWatchDescription = 'All operations';
  final _watches = <String, Stopwatch>{};

  CodegenTiming() {
    _watches[_mainWatchDescription] = new Stopwatch();
  }

  Stopwatch get _mainWatch => _watches[_mainWatchDescription];
  bool get isRunning => _mainWatch.isRunning;

  /// Starts the main timing watch.
  void start() => _mainWatch.start();

  /// Stops the main timing watch.
  void stop() => _mainWatch.stop();

  /// Tracks the time taken by [operation].
  ///
  /// [writeLogSummary] will output the total time elapsed by all operations
  /// with the same [description] in the order in which they were first
  /// executed.
  T trackOperation<T>(String description, T operation()) => _trackTiming(
      operation, _watches.putIfAbsent(description, () => new Stopwatch()));

  /// Tracks [operation] that should be totaled using [watch].
  ///
  /// This method expects that [operation] will not return a [Stream].
  T _trackTiming<T>(T operation(), Stopwatch watch) {
    assert(isRunning);
    watch.start();
    final retVal = operation();
    if (retVal is Future) {
      return retVal.then((operationValue) {
        assert(isRunning);
        watch.stop();
        return operationValue;
      }) as T;
    } else {
      watch.stop();
      return retVal;
    }
  }

  /// Writes a timing summary to [logger].
  void writeLogSummary(Logger logger) {
    _watches.forEach((description, watch) {
      logger.info('$description took ${watch.elapsedMilliseconds}ms');
    });
  }
}
