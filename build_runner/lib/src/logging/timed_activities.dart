// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../build_plan/phase.dart';
import 'ansi_buffer.dart';
import 'build_log.dart';

/// An activity timed by [BuildLog].
///
/// Time spent by builders is reported bucketed by [TimedActivity].
extension type TimedActivity(String name) {
  /// Analyzing code with `package:analyzer`.
  static final TimedActivity analyze = TimedActivity._('analyzing');

  /// Creating the SDK summary.
  static final TimedActivity analyzeSdk = TimedActivity._('sdk');

  /// Builder code.
  static final TimedActivity build = TimedActivity._('building');

  /// `build_runner`'s incremental build logic.
  static final TimedActivity track = TimedActivity._('tracking');

  /// `build_runner`'s analyzer setup, but not the analysis itself.
  static final TimedActivity resolve = TimedActivity._('resolving');

  /// Reading files.
  static final TimedActivity read = TimedActivity._('reading');

  /// Writing or deleting files.
  static final TimedActivity write = TimedActivity._('writing');

  TimedActivity._(this.name);

  /// [TimedActivity] for the phase [phase].
  ///
  /// Only lazy builds, which means builds that are triggered by a required
  /// build, are tracked in this way.
  TimedActivity.lazyPhase(InBuildPhase phase) : name = phase.displayName;

  /// Runs [function] attributing the time spent to this activity.
  ///
  /// Nested `runAsync` or `run` calls switch atribution to the innermost
  /// activity, then resume attributing to the outer activity when they finish.
  Future<T> runAsync<T>(Future<T> Function() function) =>
      buildLog.activities._runAsync(
        activity: this,
        phaseName: buildLog.currentPhaseName,
        function: function,
      );

  /// Runs [function] attributing the time spent to this activity.
  ///
  /// Nested `runAsync` or `run` calls switch atribution to the innermost
  /// activity, then resume attributing to the outer activity when they finish.
  T run<T>(T Function() function) => buildLog.activities._run(
    activity: this,
    phaseName: buildLog.currentPhaseName,
    function: function,
  );
}

/// Timings during one `build_runner` build.
class TimedActivities {
  final Stopwatch _stopwatch = Stopwatch()..start();
  Duration _attributedDuration = Duration.zero;
  final Map<String?, Map<TimedActivity, Duration>> _activities = {};

  void clear() {
    _stopwatch.reset();
    _attributedDuration = Duration.zero;
    _activities.clear();
  }

  Map<TimedActivity, Duration> durations({required String? phaseName}) =>
      _activities.putIfAbsent(phaseName, () => {});

  /// Renders activities for [phaseName].
  ///
  /// Only activities that lasted >=1s are rendered. If no activities are >=1s,
  /// an empty `String` is returned.
  String render({required String? phaseName}) {
    final result = StringBuffer();
    final entries = (_activities[phaseName] ?? {}).entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    for (final entry in entries) {
      if (entry.value.inMilliseconds < 1000) continue;
      if (result.isNotEmpty) result.write(', ');
      result.write(
        '${buildLog.renderDuration(entry.value)}${AnsiBuffer.nbsp}${entry.key}',
      );
    }
    return result.toString();
  }

  Future<T> _runAsync<T>({
    required String? phaseName,
    required TimedActivity activity,
    required Future<T> Function() function,
  }) async {
    final start = _stopwatch.elapsed;
    final startAttributionDuration = _attributedDuration;
    try {
      return await function();
    } finally {
      final end = _stopwatch.elapsed;
      final thisAttributedDuration =
          end - start - _attributedDuration + startAttributionDuration;
      _attributedDuration += thisAttributedDuration;
      _record(phaseName, activity, thisAttributedDuration);
    }
  }

  T _run<T>({
    required String? phaseName,
    required TimedActivity activity,
    required T Function() function,
  }) {
    final start = _stopwatch.elapsed;
    final startAttributionDuration = _attributedDuration;
    try {
      return function();
    } finally {
      final end = _stopwatch.elapsed;
      final thisAttributedDuration =
          end - start - _attributedDuration + startAttributionDuration;
      _attributedDuration += thisAttributedDuration;
      _record(phaseName, activity, thisAttributedDuration);
    }
  }

  void _record(String? phaseName, TimedActivity activity, Duration duration) {
    final durations = this.durations(phaseName: phaseName);
    durations[activity] = (durations[activity] ?? Duration.zero) + duration;
  }
}
