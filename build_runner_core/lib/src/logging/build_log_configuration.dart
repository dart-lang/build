// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:built_value/built_value.dart';
import 'package:logging/logging.dart';

part 'build_log_configuration.g.dart';

enum BuildLogMode {
  /// Line by line logging.
  simple,

  /// For `build_daemon`, as `simple` but log errors to stderr.
  daemon,

  /// Advanced log mode for builds.
  ///
  /// If a console is available, progress is shown and updated in place instead
  /// of line by line logging.
  build,
}

abstract class BuildLogConfiguration
    implements Built<BuildLogConfiguration, BuildLogConfigurationBuilder> {
  BuildLogMode get mode;

  /// Whether info from builders is displayed.
  bool get verbose;

  /// Optionally, a callback that will receive all log messages.
  ///
  /// If set, normal output is turned off.
  void Function(LogRecord)? get onLog;

  /// The root package of the build.
  ///
  /// If set, the package name will be omitted when rendering asset ids.
  String? get rootPackageName;

  /// Default configuration.
  factory BuildLogConfiguration() => _$BuildLogConfiguration._(
    verbose: false,
    onLog: null,
    mode: BuildLogMode.simple,
  );
  BuildLogConfiguration._();
}
