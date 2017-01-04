import 'dart:async';

import 'package:logging/logging.dart';

/// Tracks timing related to source gen actions.
class SourceGenTiming {
  static const _mainWatchDescription = 'All operations';
  final _watches = <String, Stopwatch>{};

  SourceGenTiming() {
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
  dynamic/*=T*/ trackOperation/*<T>*/(
          String description, dynamic/*=T*/ operation()) =>
      _trackTiming(
          operation, _watches.putIfAbsent(description, () => new Stopwatch()));

  /// Tracks [operation] that should be totaled using [watch].
  ///
  /// This method expects that [operation] will not return a [Stream].
  dynamic/*=T*/ _trackTiming/*<T>*/(
      dynamic/*=T*/ operation(), Stopwatch watch) {
    assert(isRunning);
    watch.start();
    final retVal = operation();
    if (retVal is Future) {
      return retVal.then((operationValue) {
        assert(isRunning);
        watch.stop();
        return operationValue;
      }) as dynamic/*=T*/;
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
