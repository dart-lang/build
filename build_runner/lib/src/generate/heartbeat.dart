// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:async/async.dart';
import 'package:logging/logging.dart';
import 'package:millisecond/millisecond.dart' as ms;

var _logger = new Logger('Heartbeat');

/// Watches [Logger.root] and if there are no logs for [waitDuration] then it
/// will log a heartbeat message with the current elapsed time since [start] was
/// originally invoked.
class HeartbeatLogger {
  CancelableOperation _nextHeartbeat;
  StreamSubscription<LogRecord> _listener;
  Stopwatch _watch;

  /// The amount of time between heartbeats.
  final Duration waitDuration;

  HeartbeatLogger({Duration waitDuration})
      : this.waitDuration = waitDuration ?? const Duration(seconds: 5);

  /// Starts this heartbeat logger, must not already be started.
  void start() {
    if (_watch != null || _nextHeartbeat != null || _listener != null) {
      throw new StateError('HeartbeatLogger already started');
    }
    _watch = new Stopwatch()..start();
    _resetHeartbeat();
    _listener = Logger.root.onRecord.listen((_) => _resetHeartbeat());
  }

  /// Stops this heartbeat logger, must already be started.
  void stop() {
    if (_watch == null || _nextHeartbeat == null || _listener == null) {
      throw new StateError('HeartbeatLogger was never started');
    }
    _watch.stop();
    _watch = null;
    _nextHeartbeat.cancel();
    _nextHeartbeat = null;
    _listener.cancel();
    _listener = null;
  }

  /// Resets the current [_nextHeartbeat] operation.
  void _resetHeartbeat() {
    _nextHeartbeat?.cancel();
    _nextHeartbeat =
        new CancelableOperation.fromFuture(new Future.delayed(waitDuration));
    _nextHeartbeat.value.then((_) {
      var formattedTime = ms.format(_watch.elapsedMilliseconds, long: true);
      _logger.info('... still running ($formattedTime so far)');
    });
  }
}
