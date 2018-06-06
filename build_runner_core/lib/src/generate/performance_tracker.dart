// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@experimental
library build_runner.src.generate.performance_tracker;

import 'dart:async';

import 'package:build/build.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

import '../util/clock.dart';
import 'phase.dart';

// part 'performance_tracker.g.dart';

/// The timings of an operation, including its [startTime], [stopTime], and
/// [duration].
@JsonSerializable()
class Timings {
  Duration get duration => stopTime.difference(startTime);

  final DateTime startTime;
  final DateTime stopTime;

  Timings(this.startTime, this.stopTime);

  // factory Timings.fromJson(Map<String, dynamic> json) =>
  //     _$TimingsFromJson(json);
}

/// The [Timings] of an entire build, including all its [actions].
@JsonSerializable()
class BuildPerformance extends Timings {
  /// The [Timings] of each phase ran in this build.
  final Iterable<BuildPhasePerformance> phases;

  /// The [Timings] of running an individual [Builder] on an individual input.
  final Iterable<BuilderActionPerformance> actions;

  BuildPerformance(
      this.phases, this.actions, DateTime startTime, DateTime stopTime)
      : super(startTime, stopTime);

  // factory BuildPerformance.fromJson(Map<String, dynamic> json) =>
  //     _$BuildPerformanceFromJson(json);
}

/// The [Timings] of a full [BuildPhase] within a larger build.
@JsonSerializable()
class BuildPhasePerformance extends Timings {
  final BuildPhase action;

  BuildPhasePerformance(this.action, DateTime startTime, DateTime stopTime)
      : super(startTime, stopTime);

  // factory BuildPhasePerformance.fromJson(Map<String, dynamic> json) =>
  //     _$BuildPhasePerformanceFromJson(json);
}

/// The [Timings] of a [builderKey] running on [primaryInput] within a build.
@JsonSerializable()
class BuilderActionPerformance extends Timings {
  final String builderKey;
  final AssetId primaryInput;
  final Iterable<BuilderActionPhasePerformance> phases;

  BuilderActionPerformance(this.builderKey, this.primaryInput, this.phases,
      DateTime startTime, DateTime stopTime)
      : super(startTime, stopTime);

  // factory BuilderActionPerformance.fromJson(Map<String, dynamic> json) =>
  //     _$BuilderActionPerformanceFromJson(json);
}

/// The [Timings] of a particular task within a builder action.
///
/// This is some slice of overall [BuilderActionPerformance].
@JsonSerializable()
class BuilderActionPhasePerformance extends Timings {
  final String label;

  BuilderActionPhasePerformance(
      this.label, DateTime startTime, DateTime stopTime)
      : super(startTime, stopTime);

  // factory BuilderActionPhasePerformance.fromJson(Map<String, dynamic> json) =>
  //     _$BuilderActionPhasePerformanceFromJson(json);
}

/// Interface for tracking the overall performance of a build.
abstract class BuildPerformanceTracker
    implements TimeTracker, BuildPerformance {
  /// Tracks [runPhase] which performs [action] on all inputs in a phase, and
  /// return the outputs generated.
  Future<Iterable<AssetId>> trackBuildPhase(
      BuildPhase action, Future<Iterable<AssetId>> runPhase());

  /// Returns a [BuilderActionTracker] for tracking [builderKey] on
  /// [primaryInput] and adds it to [actions].
  BuilderActionTracker startBuilderAction(
      AssetId primaryInput, String builderKey);

  factory BuildPerformanceTracker() => new _BuildPerformanceTrackerImpl();

  /// A [BuildPerformanceTracker] with as little overhead as possible. Does no
  /// actual tracking and does not implement many fields/methods.
  factory BuildPerformanceTracker.noOp() =>
      _NoOpBuildPerformanceTracker.sharedInstance;
}

/// Real implementation of [BuildPerformanceTracker].
///
/// Use [BuildPerformanceTracker] factory to get an instance.
class _BuildPerformanceTrackerImpl extends Object
    with _TimeTrackerImpl
    implements BuildPerformanceTracker {
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
  @override
  Future<Iterable<AssetId>> trackBuildPhase(
      BuildPhase action, Future<Iterable<AssetId>> runPhase()) {
    assert(startTime != null && stopTime == null);
    var tracker = new BuildPhaseTracker(action);
    _phases.add(tracker);
    return tracker.track(runPhase);
  }

  /// Returns a new [BuilderActionTracker] and adds it to [actions].
  ///
  /// The [BuilderActionTracker] will already be started, but you must stop it.
  @override
  BuilderActionTracker startBuilderAction(
      AssetId primaryInput, String builderKey) {
    assert(startTime != null && stopTime == null);
    var tracker = new BuilderActionTracker(primaryInput, builderKey)..start();
    _actions.add(tracker);
    return tracker;
  }
}

/// No-op implementation of [BuildPerformanceTracker].
///
/// Read-only fields will throw, and tracking methods just directly invoke their
/// closures without tracking anything.
///
/// Use [BuildPerformanceTracker.noOp] to get an instance.
class _NoOpBuildPerformanceTracker extends Object
    with _NoOpTimeTracker
    implements BuildPerformanceTracker {
  static final _NoOpBuildPerformanceTracker sharedInstance =
      new _NoOpBuildPerformanceTracker();

  @override
  Iterable<BuilderActionTracker> get actions => throw new UnimplementedError();

  @override
  Iterable<BuildPhaseTracker> get phases => throw new UnimplementedError();

  @override
  BuilderActionTracker startBuilderAction(
          AssetId primaryInput, String builderKey) =>
      new BuilderActionTracker.noOp();

  @override
  Future<Iterable<AssetId>> trackBuildPhase(
          BuildPhase action, Future<Iterable<AssetId>> runPhase()) =>
      runPhase();
}

/// Internal class that tracks the [Timings] of an entire [BuildPhase].
///
/// Tracks total time it took to run on all inputs available to that action.
///
/// Use [track] to start actually tracking an operation.
///
/// This is only meaningful for non-lazy phases.
class BuildPhaseTracker extends Object
    with _TimeTrackerImpl
    implements BuildPhasePerformance {
  @override
  final BuildPhase action;

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

/// Interface for tracking the [Timings] of an indiviual [Builder] on a given
/// primary input.
abstract class BuilderActionTracker
    implements TimeTracker, BuilderActionPerformance {
  /// Tracks the time of [runPhase] and associates it with [label].
  FutureOr<T> track<T>(FutureOr<T> runPhase(), String label);

  factory BuilderActionTracker(AssetId primaryInput, String builderKey) =>
      new _BuilderActionTrackerImpl(primaryInput, builderKey);

  /// A [BuilderActionTracker] with as little overhead as possible. Does no
  /// actual tracking and does not implement many fields/methods.
  factory BuilderActionTracker.noOp() =>
      _NoOpBuilderActionTracker._sharedInstance;
}

/// Real implementation of [BuilderActionTracker] which records timings.
///
/// Use the [BuilderActionTracker] factory to get an instance.
class _BuilderActionTrackerImpl extends Object
    with _TimeTrackerImpl
    implements BuilderActionTracker {
  @override
  final String builderKey;
  @override
  final AssetId primaryInput;

  @override
  final List<BuilderActionPhaseTracker> phases = [];

  _BuilderActionTrackerImpl(this.primaryInput, this.builderKey);

  @override
  FutureOr<T> track<T>(FutureOr<T> action(), String label) {
    var tracker = new BuilderActionPhaseTracker(label);
    phases.add(tracker);
    tracker.start();
    var result = action();
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

/// No-op instance of [BuilderActionTracker] which does nothing and throws an
/// unimplemented error for everything but [track], which delegates directly to
/// the wrapped function.
///
/// Use the [BuilderActionTracker.noOp] factory to get an instance.
class _NoOpBuilderActionTracker extends Object
    with _NoOpTimeTracker
    implements BuilderActionTracker {
  static final _NoOpBuilderActionTracker _sharedInstance =
      new _NoOpBuilderActionTracker();

  @override
  String get builderKey => throw new UnimplementedError();

  @override
  Duration get duration => throw new UnimplementedError();

  @override
  Iterable<BuilderActionPhasePerformance> get phases =>
      throw new UnimplementedError();

  @override
  AssetId get primaryInput => throw new UnimplementedError();

  @override
  FutureOr<T> track<T>(FutureOr<T> runPhase(), String label) => runPhase();
}

/// Tracks the [Timings] of an indivual task.
///
/// These represent a slice of the [BuilderActionPerformance].
class BuilderActionPhaseTracker extends Object
    with _TimeTrackerImpl
    implements BuilderActionPhasePerformance {
  @override
  final String label;

  BuilderActionPhaseTracker(this.label);
}

/// Interface for tracking the [Timings] of an operation using the [start] and
/// [stop] methods.
abstract class TimeTracker implements Timings {
  factory TimeTracker() => new _TimeTrackerImpl();
  factory TimeTracker.noOp() => _NoOpTimeTracker.sharedInstance;

  void start();
  void stop();
}

/// Implementation of a real [TimeTracker].
///
/// Use [TimeTracker] factory to get an instance.
class _TimeTrackerImpl implements TimeTracker {
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
}

/// No-op implementation of [TimeTracker] that does nothing.
///
/// Use [TimeTracker.noOp] factory to get an instance.
class _NoOpTimeTracker implements TimeTracker {
  static final sharedInstance = new _NoOpTimeTracker();

  @override
  Duration get duration => throw new UnimplementedError();
  @override
  DateTime get startTime => throw new UnimplementedError();
  @override
  DateTime get stopTime => throw new UnimplementedError();

  @override
  void start() {}

  @override
  void stop() {}
}
