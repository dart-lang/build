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
  /// The [Timings] of each phase ran in this build.
  Iterable<BuildPhasePerformance> get phases;

  /// The [Timings] of running an individual [Builder] on an individual input.
  Iterable<BuilderActionPerformance> get actions;
}

/// The [Timings] of a full [BuildAction] within a larger build.
abstract class BuildPhasePerformance implements Timings {
  BuildAction get action;
}

/// The [Timings] of a [builder] running on [primaryInput] within a build.
abstract class BuilderActionPerformance implements Timings {
  Builder get builder;
  AssetId get primaryInput;
  Iterable<BuilderActionPhasePerformance> get phases;
}

/// The [Timings] of a particular [BuilderActionPhase].
///
/// This is some slice of overall [BuilderActionPerformance].
abstract class BuilderActionPhasePerformance implements Timings {
  BuilderActionPhase get phase;
}

/// Internal class that tracks the [Timings] of an entire build.
class BuildPerformanceTracker extends TimeTracker implements BuildPerformance {
  /// All the actions ran in this build.
  ///
  /// Use [trackBuildPhase] to track whole [BuildAction]s (phases).
  @override
  Iterable<BuildPhaseTracker> get phases => _phases;
  final _phases = <BuildPhaseTracker>[];

  @override
  Iterable<BuilderActionTracker> get actions => _actions;
  final _actions = <BuilderActionTracker>[];

  /// Tracks [action] which is ran with [runPhase].
  ///
  /// This represents running a [Builder] on a group of sources.
  ///
  /// Returns all the outputs generated by the phase.
  Future<Iterable<AssetId>> trackBuildPhase(
      BuildAction action, Future<Iterable<AssetId>> runPhase()) {
    assert(startTime != null && stopTime == null);
    var tracker = new BuildPhaseTracker(action);
    _phases.add(tracker);
    return tracker.track(runPhase);
  }

  /// Returns a new [BuilderActionTracker] and adds it to [actions].
  ///
  /// The [BuilderActionTracker] will already be started, but you must stop it.
  BuilderActionTracker startBuilderAction(
      AssetId primaryInput, Builder builder) {
    assert(startTime != null && stopTime == null);
    var tracker = new BuilderActionTracker(primaryInput, builder)..start();
    _actions.add(tracker);
    return tracker;
  }
}

/// Internal class that tracks the [Timings] of an entire [BuildAction].
///
/// Tracks total time it took to run on all inputs available to that action.
///
/// Use [track] to start actually tracking an operation.
///
/// This is only meaningful for non-lazy phases.
class BuildPhaseTracker extends TimeTracker implements BuildPhasePerformance {
  @override
  final BuildAction action;

  BuildPhaseTracker(this.action);

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

/// The phases for running a [Builder] with a single primary input.
enum BuilderActionPhase {
  // Checking if the builder should run, possibly involves building other
  // things lazily.
  Setup,
  // Actually running the builder, may involve building secondary inputs lazily.
  Build,
  // The finalizing step, updating the state of the asset graph etc.
  Finalize,
}

/// Tracks the [Timings] of an indiviual [Builder] on a given primary input.
class BuilderActionTracker extends TimeTracker
    implements BuilderActionPerformance {
  @override
  final Builder builder;
  @override
  final AssetId primaryInput;

  @override
  final List<BuilderActionPhaseTracker> phases = <BuilderActionPhaseTracker>[];

  BuilderActionTracker(this.primaryInput, this.builder);

  FutureOr<T> track<T>(FutureOr<T> runPhase(), BuilderActionPhase phase) {
    var tracker = new BuilderActionPhaseTracker(phase);
    phases.add(tracker);
    tracker.start();
    var result = runPhase();
    if (result is Future<T>) {
      return result.then((actualResult) {
        tracker.stop();
        return actualResult;
      });
    } else {
      tracker.stop();
      return result;
    }
  }
}

/// Tracks the [Timings] of an indivual [BuilderActionPhase].
///
/// These represent a slice of the [BuilderActionPerformance].
class BuilderActionPhaseTracker extends TimeTracker
    implements BuilderActionPhasePerformance {
  @override
  final BuilderActionPhase phase;

  BuilderActionPhaseTracker(this.phase);
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
