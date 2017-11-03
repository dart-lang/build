// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:io/io.dart';

import 'package:build_runner/src/build_script_generate/build_script_generate.dart';

Future<Null> main() async {
  await ensureBuildScript();
  var dart = Platform.resolvedExecutable;
  var buildRun = await new ProcessManager().spawn(dart, [scriptLocation]);
  await buildRun.exitCode;
  await ProcessManager.terminateStdIn();
}
