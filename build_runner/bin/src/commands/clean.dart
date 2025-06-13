// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:build_runner/src/entrypoint/base_command.dart' show lineLength;
import 'package:build_runner/src/entrypoint/clean.dart' show clean;
import 'package:logging/logging.dart';

class CleanCommand extends Command<int> {
  @override
  final argParser = ArgParser(usageLineLength: lineLength);

  @override
  String get name => 'clean';
  final logger = Logger('clean');

  @override
  String get description =>
      'Deletes the build cache. The next build will be a full build.';

  @override
  Future<int> run() async {
    clean();
    return 0;
  }
}
