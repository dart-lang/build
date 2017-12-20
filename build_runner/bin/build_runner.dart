// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:io/io.dart';
import 'package:logging/logging.dart';

import 'package:build_runner/src/build_script_generate/build_script_generate.dart';
import 'package:build_runner/src/logging/std_io_logging.dart';

Future<Null> main(List<String> args) async {
  var logListener = Logger.root.onRecord.listen(stdIOLogListener);
  await ensureBuildScript();
  var dart = Platform.resolvedExecutable;
  final innerArgs = [scriptLocation]..addAll(args);
  if (stdioType(stdin) == StdioType.TERMINAL &&
      !args.any((a) => a.contains('assume-tty'))) {
    innerArgs.add('--assume-tty');
  }
  var buildRun = await new ProcessManager().spawn(dart, innerArgs);
  await buildRun.exitCode;
  await ProcessManager.terminateStdIn();
  await logListener.cancel();
}
