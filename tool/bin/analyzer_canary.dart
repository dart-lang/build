// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:build_development_tools/analyzer_canary.dart';

/// Runs the analyzer canary.
///
/// See `.github/workflows/analyzer_canary.yaml`.
Future<void> main(List<String> args) async {
  if (args.length != 1) {
    print('Usage: dart run tool/bin/analyzer_canary.dart <work_dir>');
    exit(64);
  }
  await runAnalyzerCanary(args.single);
}
