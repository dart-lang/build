// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:io/io.dart';

import '../constants.dart';
import '../logging/build_log.dart';
import 'build_runner_command.dart';

class CleanCommand implements BuildRunnerCommand {
  @override
  Future<int> run() async {
    buildLog.doing('Deleting the build cache.');
    final generatedDir = Directory(cacheDir);
    if (generatedDir.existsSync()) {
      generatedDir.deleteSync(recursive: true);
    }
    return ExitCode.success.code;
  }
}
