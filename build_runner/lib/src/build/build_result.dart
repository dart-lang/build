// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:meta/meta.dart';

import '../io/finalized_reader.dart';
import 'performance_tracker.dart';

/// The result of an individual build, this may be an incremental build or
/// a full build.
class BuildResult {
  /// The status of this build.
  final BuildStatus status;

  /// The type of failure.
  final FailureType? failureType;

  /// All outputs created/updated during this build.
  final List<AssetId> outputs;

  // The build output.
  final FinalizedReader? finalizedReader;

  /// The [BuildPerformance] broken out by build action, may be `null`.
  @experimental
  final BuildPerformance? performance;

  BuildResult(
    this.status,
    List<AssetId> outputs, {
    this.finalizedReader,
    this.performance,
    FailureType? failureType,
  }) : outputs = List.unmodifiable(outputs),
       failureType =
           failureType == null && status == BuildStatus.failure
               ? FailureType.general
               : failureType;
  @override
  String toString() {
    if (status == BuildStatus.success) {
      return '''

Build Succeeded!
''';
    } else {
      return '''

Build Failed :(
''';
    }
  }

  factory BuildResult.buildScriptChanged() => BuildResult(
    BuildStatus.failure,
    const [],
    failureType: FailureType.buildScriptChanged,
  );
}

/// The status of a build.
enum BuildStatus { success, failure }

/// The type of failure
class FailureType {
  static final general = FailureType._(1);
  static final cantCreate = FailureType._(73);
  static final buildConfigChanged = FailureType._(75);
  static final buildScriptChanged = FailureType._(75);
  final int exitCode;
  FailureType._(this.exitCode);
}
