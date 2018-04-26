// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:io/ansi.dart' as ansi;
import 'package:io/io.dart' show ExitCode;

import '../package_graph/apply_builders.dart';
import 'options.dart';

/// A common entry point to parse command line arguments and build or serve with
/// [builders].
///
/// Returns the exit code that should be set when the calling process exits. `0`
/// implies success.
Future<int> run(List<String> args, List<BuilderApplication> builders) async {
  var runner = new BuildCommandRunner(builders);
  try {
    var result = await runner.run(args);
    return result ?? 0;
  } on UsageException catch (e) {
    print(ansi.red.wrap(e.message));
    print('');
    print(e.usage);
    return ExitCode.usage.code;
  }
}
