// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import '../asset/asset.dart';

/// The result of an individual build, this may be an incremental build or
/// a full build.
class BuildResult {
  /// The status of this build.
  final BuildStatus status;

  /// The error that was thrown during this build if it failed.
  final Object exception;

  /// The [StackTrace] for [exception] if non-null.
  final StackTrace stackTrace;

  /// The type of this build.
  final BuildType buildType;

  /// All outputs created/updated during this build.
  final List<Asset> outputs;

  BuildResult(this.status, this.buildType, List<Asset> outputs,
      {this.exception, this.stackTrace})
      : outputs = new List.unmodifiable(outputs);

  @override
  String toString() {
    if (status == BuildStatus.success) {
      return '''

Build Succeeded!
Type: $buildType
''';
    } else {
      return '''

Build Failed :(
Type: $buildType
Exception: $exception
Stack Trace:
$stackTrace
''';
    }
  }
}

/// The status of a build.
enum BuildStatus { success, failure, }

/// The type of a build.
enum BuildType { incremental, full }
