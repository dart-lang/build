// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build_runner_core/src/logging/build_log.dart';
import 'package:test/test.dart';

void main() {
  group('BuildLog', () {
    late BuildLog log;

    setUp(() {
      log = BuildLog();
    });

    test('initial display', () {
      expect(
        log.render(),
        padLinesRight('''
 --- build_runner
 <1s setup,  0%'''),
      );
    });

    test('setup', () {
      log.progress(Progress.generateBuildScript);
      log.progress(Progress.compileBuildScript);
      expect(
        log.render(),
        padLinesRight('''
 --- build_runner
 <1s setup, compile build script, 25%'''),
      );
    });

    test('build with no warnings or errors', () {
      log.progress(Progress.generateBuildScript);
      log.progress(Progress.compileBuildScript);
      log.progress(Progress.newAssetGraph);
      log.progress(Progress.initialBuildCleanup);
      log.progress(Progress.updateAssetGraph);

      log.builders(['builder1', 'builder2'], {'builder1': 10, 'builder2': 15});

      log.progress(Progress.build('builder1', 'lib/foo.dart'));

      expect(
        log.render(),
        padLinesRight('''
 --- build_runner
 <1s setup
 <1s builder1, lib/foo.dart,  0%
     builder2
     cleanup'''),
      );
    });
  });
}

String padLinesRight(String output) {
  final result = StringBuffer();
  for (final line in output.split('\n')) {
    result.writeln(line.padRight(80));
  }
  return result.toString();
}
