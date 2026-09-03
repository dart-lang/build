// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:build_runner/src/build_runner.dart';

import '../test_builders.dart';

Future<void> main(List<String> arguments) async {
  final code = await BuildRunner(
    arguments: arguments,
    builderFactories: allTestBuilderFactories,
  ).run();
  await stdout.flush();
  await stderr.flush();
  exit(code);
}
