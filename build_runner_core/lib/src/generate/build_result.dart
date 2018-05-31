// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';

import 'package:build/build.dart';
import 'package:meta/meta.dart';

import 'performance_tracker.dart';

/// The result of an individual build, this may be an incremental build or
/// a full build.
class BuildResult {
  /// The status of this build.
  final BuildStatus status;

  /// The type of failure.
  final FailureType failureType;

  /// The error that was thrown during this build if it failed.
  final Object exception;

  /// The [StackTrace] for [exception] if non-null.
  final StackTrace stackTrace;

  /// All outputs created/updated during this build.
  final List<AssetId> outputs;

  /// The [BuildPerformance] broken out by build action, may be `null`.
  @experimental
  final BuildPerformance performance;

  BuildResult(this.status, List<AssetId> outputs,
      {this.exception,
      this.stackTrace,
      this.performance,
      FailureType failureType})
      : outputs = new List.unmodifiable(outputs),
        this.failureType = failureType == null && status == BuildStatus.failure
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
Exception: $exception
Stack Trace:
$stackTrace
''';
    }
  }
}

/// The status of a build.
enum BuildStatus {
  success,
  failure,
}

/// The type of failure
class FailureType {
  static const general = const FailureType._(1);
  static const cantCreate = const FailureType._(73);
  final int exitCode;
  const FailureType._(this.exitCode);
}

abstract class BuildState {
  Future<BuildResult> get currentBuild;
  Stream<BuildResult> get buildResults;
}
