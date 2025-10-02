// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:built_collection/built_collection.dart';
import 'package:meta/meta.dart';

import '../io/build_output_reader.dart';
import 'performance_tracker.dart';

/// The result of an individual build, this may be an incremental build or
/// a full build.
class BuildResult {
  /// The status of this build.
  final BuildStatus status;

  /// The type of failure.
  final FailureType? failureType;

  /// Errors reported.
  final BuiltList<String> errors;

  /// All outputs created/updated during this build.
  final BuiltList<AssetId> outputs;

  // The build output.
  final BuildOutputReader buildOutputReader;

  /// The [BuildPerformance] broken out by build action.
  @experimental
  final BuildPerformance? performance;

  BuildResult({
    required this.status,
    BuiltList<String>? errors,
    BuiltList<AssetId>? outputs,
    required this.buildOutputReader,
    this.performance,
    FailureType? failureType,
  }) : failureType =
           failureType == null && status == BuildStatus.failure
               ? FailureType.general
               : failureType,
       errors = errors ?? BuiltList(),
       outputs = outputs ?? BuiltList();

  BuildResult copyWith({
    BuildStatus? status,
    FailureType? failureType,
    BuiltList<String>? errors,
  }) => BuildResult(
    status: status ?? this.status,
    errors: errors ?? this.errors,
    outputs: outputs,
    buildOutputReader: buildOutputReader,
    performance: performance,
    failureType: failureType ?? this.failureType,
  );

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
    status: BuildStatus.failure,
    failureType: FailureType.buildScriptChanged,
    buildOutputReader: BuildOutputReader.empty(),
  );
}

/// The status of a build.
enum BuildStatus { success, failure }

/// The type of failure
class FailureType {
  static final general = FailureType._(1);
  static final cantCreate = FailureType._(73);
  static final buildScriptChanged = FailureType._(75);
  final int exitCode;
  FailureType._(this.exitCode);
}
