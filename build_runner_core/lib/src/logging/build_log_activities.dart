// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../generate/phase.dart';
import 'ansi_buffer.dart';
import 'build_log.dart';
import 'build_log_stage.dart';

class BuildLogActivities {
  final Stopwatch _stopwatch = Stopwatch()..start();
  Duration _attributedDuration = Duration.zero;
  final Map<InBuildPhase?, Map<ActivityType, Duration>> _activities = {};

  /// Runs [function] adding the time spent to the measure of the specified
  /// [activity] of the currently-running [Stage].
  Future<T> runActivityAsync<T>({
    required InBuildPhase? phase,
    required ActivityType activity,
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

  /// Runs [function] adding the time spent to the measure of the specified
  /// [activity] of the currently-running [Stage].
  T runActivity<T>({
    required InBuildPhase? phase,
    required ActivityType activity,
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

  Map<ActivityType, Duration> durations({required InBuildPhase? phase}) =>
      _activities.putIfAbsent(phase, () => {});

  void _record(InBuildPhase? phase, ActivityType activity, Duration duration) {
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

extension type ActivityType(String name) {
  static final ActivityType analyze = ActivityType._('analyzing');
  static final ActivityType analyzeSdk = ActivityType._('analyzing sdk');
  static final ActivityType build = ActivityType._('building');
  static final ActivityType track = ActivityType._('tracking');
  static final ActivityType resolve = ActivityType._('resolving');
  static final ActivityType read = ActivityType._('reading');
  static final ActivityType write = ActivityType._('writing');

  ActivityType.optionalBuilder(this.name);
  ActivityType._(this.name);
}
