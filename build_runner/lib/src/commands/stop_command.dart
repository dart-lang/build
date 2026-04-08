// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:io/io.dart';

import 'build_runner_command.dart';

class StopCommand implements BuildRunnerCommand {
  @override
  Future<int> run() async {
    // The lock is taken on startup in `build_runner.dart`, any other running
    // `build_runner` was already notified and has closed.
    return ExitCode.success.code;
  }
}
