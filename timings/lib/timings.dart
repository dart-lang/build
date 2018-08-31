// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:timings/src/clock.dart';

/// The timings of an operation, including its [startTime], [stopTime], and
/// [duration].
abstract class Timings {
  /// The total duration of this operation, equivalent to taking the difference
  /// between [stopTime] and [startTime].
  Duration get duration => stopTime.difference(startTime);

  DateTime get startTime;

  DateTime get stopTime;
}

/// The timings of an async operation, consist of several sync [slices] and
/// includes total [startTime], [stopTime], and [duration].
abstract class AsyncTimings extends Timings {
  final slices = <Timings>[];

  @override
  DateTime get startTime => slices.first?.startTime;

  @override
  DateTime get stopTime => slices.last?.stopTime;

  Duration get innerDuration => slices.fold(
      Duration.zero, (duration, timings) => duration + timings.duration);
}

abstract class TimeTracker implements Timings {
  T track<T>(T Function() action);
}

/// Interface for tracking the [Timings] of an operation using the [start] and
/// [stop] methods.
abstract class SyncTimeTracker implements TimeTracker {
  factory SyncTimeTracker() => _SyncTimeTrackerImpl();

  factory SyncTimeTracker.kindaAsync() => _FutureTimeTrackerImpl();

  factory SyncTimeTracker.noOp() => _NoOpSyncTimeTracker.sharedInstance;

  void start();

  void stop();
}

/// Implementation of a real [SyncTimeTracker].
///
/// Use [SyncTimeTracker] factory to get an instance.
class _SyncTimeTrackerImpl extends Timings implements SyncTimeTracker {
  /// When this operation started, call [start] to set this.
  @override
  DateTime get startTime => _startTime;
  DateTime _startTime;

  /// When this operation stopped, call [stop] to set this.
  @override
  DateTime get stopTime => _stopTime;
  DateTime _stopTime;

  /// Start tracking this operation, must only be called once, before [stop].
  @override
  void start() {
    assert(_startTime == null && _stopTime == null);
    _startTime = now();
  }

  /// Stop tracking this operation, must only be called once, after [start].
  @override
  void stop() {
    assert(_startTime != null && _stopTime == null);
    _stopTime = now();
  }

  @override
  T track<T>(T Function() action) {
    start();
    try {
      return action();
    } finally {
      stop();
    }
  }
}

/// Implementation of [SyncTimeTracker] that can handle async actions
///
/// Async actions returning [Future] will be tracked as single sync time span
/// from the beginning of execution till completion of future
///
/// Use [SyncTimeTracker.kindaAsync] factory to get an instance.
class _FutureTimeTrackerImpl extends _SyncTimeTrackerImpl {
  @override
  T track<T>(T Function() action) {
    T result;
    start();
    try {
      result = action();
    } catch (_) {
      stop();
      rethrow;
    }
    if (result is Future) {
      return result.whenComplete(stop) as T;
    } else {
      stop();
      return result;
    }
  }
}

/// No-op implementation of [SyncTimeTracker] that does nothing.
///
/// Use [SyncTimeTracker.noOp] factory to get an instance.
class _NoOpSyncTimeTracker implements SyncTimeTracker {
  static final sharedInstance = _NoOpSyncTimeTracker();

  @override
  Duration get duration => throw UnimplementedError();

  @override
  DateTime get startTime => throw UnimplementedError();

  @override
  DateTime get stopTime => throw UnimplementedError();

  @override
  void start() {}

  @override
  void stop() {}

  @override
  T track<T>(T Function() action) => action();
}

abstract class AsyncTimeTracker implements AsyncTimings, TimeTracker {
  factory AsyncTimeTracker() => _AsyncTimeTrackerImpl();

  factory AsyncTimeTracker.noOp() => _NoOpAsyncTimeTracker.sharedInstance;
}

/// Implementation of a real [AsyncTimeTracker].
///
/// Use [AsyncTimeTracker] factory to get an instance.
class _AsyncTimeTrackerImpl extends AsyncTimings implements AsyncTimeTracker {
  final internalFutures = <Future>[];

  T _trackSyncSlice<T>(ZoneDelegate parent, Zone zone, T Function() action) {
    // Don't track time in nested runs twice
    if (slices.isEmpty || slices.last.stopTime != null) {
      var timer = SyncTimeTracker();
      slices.add(timer);

      var completer = Completer();
      internalFutures.add(completer.future);

      try {
        // Pass to parent zone, in case of overwritten clock
        return parent.runUnary(zone, timer.track, action);
      } finally {
        completer.complete();
      }
    } else {
      return action();
    }
  }

  @override
  T track<T>(T Function() action) {
    var result = runZoned(action,
        zoneSpecification: ZoneSpecification(
          run: <R>(Zone self, ZoneDelegate parent, Zone zone, R Function() f) {
            return _trackSyncSlice(parent, zone, () => parent.run(zone, f));
          },
          runUnary: <R, T>(Zone self, ZoneDelegate parent, Zone zone,
              R Function(T) f, T arg) {
            return _trackSyncSlice(
                parent, zone, () => parent.runUnary(zone, f, arg));
          },
          runBinary: <R, T1, T2>(Zone self, ZoneDelegate parent, Zone zone,
              R Function(T1, T2) f, T1 arg1, T2 arg2) {
            return _trackSyncSlice(
                parent, zone, () => parent.runBinary(zone, f, arg1, arg2));
          },
        ));
    if (result is Future) {
      return result.whenComplete(() => Future.wait(internalFutures)) as T;
    } else {
      return result;
    }
  }
}

/// No-op implementation of [AsyncTimeTracker] that does nothing.
///
/// Use [AsyncTimeTracker.noOp] factory to get an instance.
class _NoOpAsyncTimeTracker implements AsyncTimeTracker {
  static final sharedInstance = _NoOpAsyncTimeTracker();

  @override
  Duration get duration => throw UnimplementedError();

  @override
  Duration get innerDuration => throw UnimplementedError();

  @override
  DateTime get startTime => throw UnimplementedError();

  @override
  DateTime get stopTime => throw UnimplementedError();

  @override
  List<Timings> get slices => throw UnimplementedError();

  @override
  T track<T>(T Function() action) => action();
}
