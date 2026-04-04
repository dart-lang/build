// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:io/io.dart';

import '../build_runner.dart';
import '../constants.dart';
import 'build_runner_command.dart';

class CleanCommand implements BuildRunnerCommand {
  @override
  Future<int> run() async {
    // TRICKY: Release the universal lock handle first. On Windows, deleting
    // a directory containing an open file handle causes a crash.
    BuildRunner.releaseLock();

    final generatedDir = Directory(cacheDirectoryPath);
    if (generatedDir.existsSync()) {
      generatedDir.deleteSync(recursive: true);
    }
    return ExitCode.success.code;
  }
}
