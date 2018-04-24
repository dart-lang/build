// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:logging/logging.dart';

import '../logging/human_readable_duration.dart';

var _logger = new Logger('Heartbeat');

abstract class Heartbeat {
  Stopwatch _totalWatch;
  Stopwatch _intervalWatch;
  Timer _timer;

  /// The amount of time between heartbeats.
  final Duration waitDuration;

  Heartbeat({Duration waitDuration})
      : this.waitDuration = waitDuration ?? const Duration(seconds: 5);

  /// Invoked if [waitDuration] time has elapsed since the last call to [reset].
  void onDurationReached(Duration duration);

  /// Starts this heartbeat logger, must not already be started.
  void start() {
    if (_totalWatch != null || _intervalWatch != null || _timer != null) {
      throw new StateError('HeartbeatLogger already started');
    }
    _totalWatch = new Stopwatch()..start();
    _intervalWatch = new Stopwatch()..start();
    reset();
    _timer =
        new Timer.periodic(const Duration(milliseconds: 100), _checkDuration);
  }

  /// Resets the current [_intervalWatch].
  void reset() {
    _intervalWatch.reset();
  }

  /// Stops this heartbeat logger, must already be started.
  void stop() {
    if (_totalWatch == null || _intervalWatch == null || _timer == null) {
      throw new StateError('HeartbeatLogger was never started');
    }
    _totalWatch.stop();
    _totalWatch = null;
    _intervalWatch.stop();
    _intervalWatch = null;
    _timer.cancel();
    _timer = null;
  }

  void _checkDuration(_) {
    if (_intervalWatch.elapsed < waitDuration) return;
    onDurationReached(_intervalWatch.elapsed);
    reset();
  }
}

/// Watches [Logger.root] and if there are no logs for [waitDuration] then it
/// will log a heartbeat message with the current elapsed time since [start] was
/// originally invoked.
class HeartbeatLogger extends Heartbeat {
  StreamSubscription<LogRecord> _listener;

  /// Will be invoked with each original log message and the returned value will
  /// be logged instead.
  final String Function(String original) transformLog;

  HeartbeatLogger({Duration waitDuration, this.transformLog})
      : super(waitDuration: waitDuration);

  /// Start listening to logs.
  @override
  void start() {
    super.start();
    _listener = Logger.root.onRecord.listen((_) => _resetHeartbeat());
  }

  /// Stops listenting to the logger;
  @override
  void stop() {
    _listener.cancel();
    _listener = null;
  }

  /// Logs a heartbeat message if [_intervalWatch] has been running for
  /// [waitDuration] or more.
  @override
  onDurationReached(Duration elapsed) {
    var formattedTime = humanReadable(elapsed);
    var message = '$formattedTime elapsed';
    if (transformLog != null) {
      message = transformLog(message);
    }
    _logger.info(message);
  }
}
