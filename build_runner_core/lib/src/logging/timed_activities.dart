// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../generate/phase.dart';
import 'ansi_buffer.dart';
import 'build_log.dart';

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

  /// [TimedActivity] for the optional phase [phase].
  ///
  /// Optional phase builds happen only if needed, and always during a required
  /// phase. So they count as a [TimedActivity] launched in that required phase.
  TimedActivity.optionalPhase(InBuildPhase phase) : name = phase.builderLabel {
    if (!phase.isOptional) throw ArgumentError('Phase not optional: $phase');
  }

  /// Runs [function] attributing the time spent to this activity.
  Future<T> runAsync<T>(Future<T> Function() function) =>
      buildLog.activities._runAsync(
        activity: this,
        phase: buildLog.currentPhase,
        function: function,
      );

  /// Runs [function] attributing the time spent to this activity.
  T run<T>(T Function() function) => buildLog.activities._run(
    activity: this,
    phase: buildLog.currentPhase,
    function: function,
  );
}

class TimedActivities {
  final Stopwatch _stopwatch = Stopwatch()..start();
  Duration _attributedDuration = Duration.zero;
  final Map<InBuildPhase?, Map<TimedActivity, Duration>> _activities = {};

  Future<T> _runAsync<T>({
    required InBuildPhase? phase,
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
      _record(phase, activity, thisAttributedDuration);
    }
  }

  T _run<T>({
    required InBuildPhase? phase,
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
      _record(phase, activity, thisAttributedDuration);
    }
  }

  Map<TimedActivity, Duration> durations({required InBuildPhase? phase}) =>
      _activities.putIfAbsent(phase, () => {});

  void _record(InBuildPhase? phase, TimedActivity activity, Duration duration) {
    final durations = this.durations(phase: phase);
    durations[activity] = (durations[activity] ?? Duration.zero) + duration;
  }

  String render({required InBuildPhase? phase}) {
    final result = StringBuffer();
    final entries = (_activities[phase] ?? {}).entries.toList();
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
}
