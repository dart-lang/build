// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:built_value/built_value.dart';
import 'package:logging/logging.dart';

import '../bootstrap/build_process_state.dart';

part 'build_log_configuration.g.dart';

abstract class BuildLogConfiguration
    implements Built<BuildLogConfiguration, BuildLogConfigurationBuilder> {
  BuildLogMode get mode;

  /// Whether info from builders is displayed.
  bool get verbose;

  /// Optionally, a callback that will receive all log messages.
  ///
  /// If set, normal output is turned off.
  void Function(LogRecord)? get onLog;

  /// If this is a single package build, the package name.
  ///
  /// If set, the package name will be omitted when rendering asset ids.
  String? get singleOutputPackage;

  /// Whether progress updates are throtled.
  bool get throttleProgressUpdates;

  /// Set to redirect output to `printOnFailure` for tests.
  void Function(String)? get printOnFailure;

  /// Sets whether ansi is available for tests.
  bool? get forceAnsiConsoleForTesting;

  /// Sets that console is available with the specified width for tests.
  int? get forceConsoleWidthForTesting;

  /// Default configuration.
  factory BuildLogConfiguration() => _$BuildLogConfiguration._(
    verbose: false,
    onLog: null,
    mode: BuildLogMode.simple,
    throttleProgressUpdates: true,
  );
  BuildLogConfiguration._();
}
