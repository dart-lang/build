// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart';

import 'phase.dart';

/// Tracks the performance of an entire build, as well as all of the
/// individual [actions] that were ran in that build.
class BuildPerformanceTracker extends TimeTracker {
  /// All the actions ran in this build.
  ///
  /// Use [trackAction] to track individual actions.
  Iterable<BuildActionTracker> get actions => _actions;
  final _actions = <BuildActionTracker>[];

  /// Tracks [action] which is ran with [runAction].
  Future<Iterable<AssetId>> trackAction(
      BuildAction action, Future<Iterable<AssetId>> runAction()) {
    var tracker = new BuildActionTracker(action);
    _actions.add(tracker);
    return tracker.track(runAction);
  }
}

/// Tracks how long it took to run an individual [BuildAction].
///
/// Tracks total time it took to run on all inputs available to that action.
///
/// It isn't feasible to accurately track how long it took to run on each
/// individual input because they are all ran at the same time.
class BuildActionTracker extends TimeTracker {
  final BuildAction action;

  BuildActionTracker(this.action);

  Future<Iterable<AssetId>> track(Future<Iterable<AssetId>> runAction()) {
    assert(startTime == null && stopTime == null);
    start();
    return runAction().then((outputs) {
      stop();
      return outputs;
    });
  }
}

/// Base class for time tracking of an individual operation.
///
/// Tracks a [startTime], [stopTime], and [duration].
class TimeTracker {
  /// When this operation started, call [start] to set this.
  DateTime get startTime => _startTime;
  DateTime _startTime;

  /// When this operation stopped, call [stop] to set this.
  DateTime get stopTime => _stopTime;
  DateTime _stopTime;

  /// The total duration of this operation, equivalent to taking the difference
  /// between [stopTime] and [startTime].
  Duration get duration {
    assert(_startTime != null && _stopTime != null);
    return new Duration(
        microseconds:
            stopTime.microsecondsSinceEpoch - startTime.microsecondsSinceEpoch);
  }

  /// Start tracking this operation, must only be called once, before [stop].
  void start() {
    assert(_startTime == null && _stopTime == null);
    _startTime = new DateTime.now();
  }

  /// Stop tracking this operation, must only be called once, after [start].
  void stop() {
    assert(_startTime != null && _stopTime == null);
    _stopTime = new DateTime.now();
  }
}
