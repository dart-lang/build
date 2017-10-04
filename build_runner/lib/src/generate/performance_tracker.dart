// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart';

import 'package:build_runner/src/util/clock.dart';
import 'phase.dart';

/// The timings of an operation, including its [startTime], [stopTime], and
/// [duration].
abstract class Timings {
  Duration get duration;
  DateTime get startTime;
  DateTime get stopTime;
}

/// The [Timings] of an entire build, including all its [actions].
abstract class BuildPerformance implements Timings {
  /// The [Timings] of each [BuildAction] ran in this build.
  Iterable<BuildActionPerformance> get actions;
}

/// The [Timings] of an [action] within a larger build.
abstract class BuildActionPerformance implements Timings {
  BuildAction get action;
}

/// Internal class that tracks the [Timings] of an entire build.
class BuildPerformanceTracker extends TimeTracker implements BuildPerformance {
  /// All the actions ran in this build.
  ///
  /// Use [trackAction] to track individual actions.
  @override
  Iterable<BuildActionTracker> get actions => _actions;
  final _actions = <BuildActionTracker>[];

  /// Tracks [action] which is ran with [runAction].
  Future<Iterable<AssetId>> trackAction(
      BuildAction action, Future<Iterable<AssetId>> runAction()) {
    assert(startTime != null && stopTime == null);
    var tracker = new BuildActionTracker(action);
    _actions.add(tracker);
    return tracker.track(runAction);
  }
}

/// Internal class that tracks the [Timings] of an individual [BuildAction].
///
/// Tracks total time it took to run on all inputs available to that action.
///
/// It isn't feasible to accurately track how long it took to run on each
/// individual input because they are all ran at the same time.
class BuildActionTracker extends TimeTracker implements BuildActionPerformance {
  @override
  final BuildAction action;

  BuildActionTracker(this.action);

  /// Runs [runAction], setting [startTime] and [stopTime] accordingly.
  ///
  /// Should never be called more than once.
  Future<Iterable<AssetId>> track(Future<Iterable<AssetId>> runAction()) {
    assert(startTime == null && stopTime == null);
    start();
    return runAction().then((outputs) {
      stop();
      return outputs;
    });
  }
}

/// Internal base class for tracking the [Timings] of an arbitrary operation.
class TimeTracker implements Timings {
  /// When this operation started, call [start] to set this.
  @override
  DateTime get startTime => _startTime;
  DateTime _startTime;

  /// When this operation stopped, call [stop] to set this.
  @override
  DateTime get stopTime => _stopTime;
  DateTime _stopTime;

  /// The total duration of this operation, equivalent to taking the difference
  /// between [stopTime] and [startTime].
  @override
  Duration get duration {
    assert(_startTime != null && _stopTime != null);
    return new Duration(
        microseconds:
            stopTime.microsecondsSinceEpoch - startTime.microsecondsSinceEpoch);
  }

  /// Start tracking this operation, must only be called once, before [stop].
  void start() {
    assert(_startTime == null && _stopTime == null);
    _startTime = now();
  }

  /// Stop tracking this operation, must only be called once, after [start].
  void stop() {
    assert(_startTime != null && _stopTime == null);
    _stopTime = now();
  }
}
