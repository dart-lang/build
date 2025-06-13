// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:build_runner_core/build_runner_core.dart';

import 'base_command.dart';

class CleanCommand extends Command<int> {
  @override
  final argParser = ArgParser(usageLineLength: lineLength);

  @override
  String get name => 'clean';

  @override
  String get description =>
      'Deletes the build cache. The next build will be a full build.';

  @override
  Future<int> run() async {
    clean();
    return 0;
  }
}

void clean() {
  buildLog.doing('Deleting the build cache.');
  var generatedDir = Directory(cacheDir);
  if (generatedDir.existsSync()) {
    generatedDir.deleteSync(recursive: true);
  }
}
