// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build_runner/build_runner.dart';

import 'options.dart';

/// A common entrypoint to parse command line arguments and build or serve with
/// [builders].
Future<int> run(List<String> args, List<BuilderApplication> builders) async {
  var runner = new BuildCommandRunner(builders);
  return (await runner.run(args)) ?? 0;
}
