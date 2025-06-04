// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math';

import 'ansi_buffer.dart';
import 'build_log.dart';

class Stage {
  final String name;
  final int length;

  final Map<StageActivity, Duration> attributions = {};
  Duration? duration;
  int? progress;
  String? note;

  Stage({required this.name, required this.length});
  factory Stage.setup() => Stage(name: 'build_runner setup', length: 8);
  factory Stage.cleanup() => Stage(name: 'build_runner cleanup', length: 4);

  final Map<String?, List<String>> infos = {};
  final Map<String?, List<String>> warnings = {};
  final Map<String?, List<String>> errors = {};

  bool get isHidden => length == 0 && !hasLogOutput;

  bool get isInProgress => progress != null && progress! < length;

  String get renderProgress {
    final result = StringBuffer('${progress ?? 0}/$length');

    if (duration != null) {
      result.write(
        '${AnsiBuffer.nbsp}in${AnsiBuffer.nbsp}'
        '${buildLog.renderDuration(duration!)}',
      );
    }

    return result.toString();
  }

  int get maxProgressWidth {
    final progressWidth = '$length/$length in '.length;
    final durationWidth =
        duration == null
            ? 3
            : max(3, buildLog.renderDuration(duration!).length);
    return progressWidth + durationWidth;
  }

  bool get hasLogOutput =>
      warnings.isNotEmpty ||
      errors.isNotEmpty ||
      (buildLog.configuration.verbose && infos.isNotEmpty);

  String get renderAttributions {
    final result = StringBuffer();
    final entries = attributions.entries.toList();
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

extension type StageActivity(String name) {
  static final StageActivity analyze = StageActivity._('analyzing');
  static final StageActivity build = StageActivity._('building');
  static final StageActivity track = StageActivity._('tracking');
  static final StageActivity resolve = StageActivity._('resolving');
  static final StageActivity read = StageActivity._('reading');
  static final StageActivity write = StageActivity._('writing');

  StageActivity.optionalBuilder(this.name);
  StageActivity._(this.name);
}
