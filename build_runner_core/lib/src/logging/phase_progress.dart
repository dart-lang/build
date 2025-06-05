// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';

import 'ansi_buffer.dart';
import 'build_log.dart';

// TODO(davidmorgan): refactor overhead, hidden, ...
class PhaseProgress {
  final int inputs;

  AssetId? nextInput;

  final Map<ActivityType, Duration> attributions = {};

  Duration duration = Duration.zero;
  int skipped = 0;
  int builtNew = 0;
  int builtSame = 0;
  int builtNothing = 0;

  PhaseProgress({required this.inputs});

  bool get isOptional => inputs == 0;

  bool get isFinished =>
      inputs == skipped + builtNew + builtSame + builtNothing;

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
