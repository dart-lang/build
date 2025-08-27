// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:build_daemon/constants.dart';

import '../build_runner_command_line.dart';

class DaemonOptions {
  final bool logRequests;
  final BuildMode buildMode;

  DaemonOptions({required this.buildMode, required this.logRequests});

  static DaemonOptions parse(BuildRunnerCommandLine commandLine) {
    final buildModeValue = commandLine.buildMode;
    BuildMode buildMode;
    if (buildModeValue == BuildMode.Auto.toString()) {
      buildMode = BuildMode.Auto;
    } else if (buildModeValue == BuildMode.Manual.toString()) {
      buildMode = BuildMode.Manual;
    } else {
      throw UsageException(
        'Unexpected value for $buildModeFlag: $buildModeValue',
        commandLine.usage,
      );
    }
    return DaemonOptions(
      logRequests: commandLine.logRequests!,
      buildMode: buildMode,
    );
  }
}
