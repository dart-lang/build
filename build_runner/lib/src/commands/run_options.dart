// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:built_collection/built_collection.dart';

import '../build_runner_command_line.dart';

class RunOptions {
  final String script;
  final BuiltList<String> options;

  RunOptions({required this.script, required this.options});

  static RunOptions parse(BuildRunnerCommandLine commandLine) {
    var rest = commandLine.rest;
    if (rest.isEmpty) {
      throw UsageException(
        'Must specify an executable to run.',
        commandLine.usage,
      );
    }
    final script = rest.first;
    rest = rest.skip(1).toBuiltList();

    if (commandLine.restArgumentsBeforeSeparator != 1) {
      throw UsageException(
        'The `run` command requires a `--` separator before any '
        'script arguments.',
        commandLine.usage,
      );
    }

    return RunOptions(script: script, options: rest);
  }
}
