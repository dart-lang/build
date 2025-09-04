// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:built_collection/built_collection.dart';

import '../build_runner_command_line.dart';

class TestOptions {
  BuiltList<String> options;

  TestOptions._(this.options);

  static TestOptions parse(BuildRunnerCommandLine commandLine) {
    if (commandLine.restArgumentsBeforeSeparator != 0) {
      throw UsageException(
        'The `test` command requires a `--` separator before any '
        'test arguments.',
        commandLine.usage,
      );
    }

    return TestOptions._(commandLine.rest);
  }
}
