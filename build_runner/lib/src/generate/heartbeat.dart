// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:logging/logging.dart';

import '../logging/human_readable_duration.dart';

var _logger = new Logger('Heartbeat');

/// Watches [Logger.root] and if there are no logs for [waitDuration] then it
/// will log a heartbeat message with the current elapsed time since [start] was
/// originally invoked.
class HeartbeatLogger {
  StreamSubscription<LogRecord> _listener;
  Stopwatch _totalWatch;
  Stopwatch _intervalWatch;
  Timer _timer;

  /// The amount of time between heartbeats.
  final Duration waitDuration;

  HeartbeatLogger({Duration waitDuration})
      : this.waitDuration = waitDuration ?? const Duration(seconds: 5);

  /// Starts this heartbeat logger, must not already be started.
  void start() {
    if (_totalWatch != null ||
        _intervalWatch != null ||
        _listener != null ||
        _timer != null) {
      throw new StateError('HeartbeatLogger already started');
    }
    _totalWatch = new Stopwatch()..start();
    _intervalWatch = new Stopwatch()..start();
    _resetHeartbeat();
    _listener = Logger.root.onRecord.listen((_) => _resetHeartbeat());
    _timer = new Timer.periodic(
        const Duration(milliseconds: 100), _logIfDurationIsMet);
  }

  /// Stops this heartbeat logger, must already be started.
  void stop() {
    if (_totalWatch == null ||
        _intervalWatch == null ||
        _listener == null ||
        _timer == null) {
      throw new StateError('HeartbeatLogger was never started');
    }
    _totalWatch.stop();
    _totalWatch = null;
    _intervalWatch.stop();
    _intervalWatch = null;
    _listener.cancel();
    _listener = null;
    _timer.cancel();
    _timer = null;
  }

  /// Resets the current [_intervalWatch].
  void _resetHeartbeat() {
    _intervalWatch.reset();
  }

  /// Logs a heartbeat message if [_intervalWatch] has been running for
  /// [waitDuration] or more.
  void _logIfDurationIsMet(_) {
    if (_intervalWatch.elapsed < waitDuration) return;

    var formattedTime = humanReadable(_totalWatch.elapsed);
    _logger.info('... still running ($formattedTime so far)');
    _resetHeartbeat();
  }
}
