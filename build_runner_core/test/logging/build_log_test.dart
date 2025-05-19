// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:build_runner_core/src/logging/build_log.dart';
import 'package:test/test.dart';

void main() {
  group('BuildLog', () {
    late BuildLog log;

    setUp(() {
      log = BuildLog.forTesting();
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
 --- build_runner compile build script
 <1s setup, 25%'''),
      );
    });

    test('build progress with no warnings or errors', () {
      log.builders(['builder1', 'builder2'], {'builder1': 10, 'builder2': 15});

      log.progress(Progress.build('builder1', 'lib/foo.dart'));

      expect(
        log.render(),
        padLinesRight('''
 --- build_runner lib/foo.dart
 <1s setup
 <1s builder1,  0%
     builder2
     cleanup'''),
      );
    });

    test('build progress with builder warnings', () {
      log.builders(['builder1', 'builder2'], {'builder1': 10, 'builder2': 15});
      log.progress(Progress.build('builder1', 'lib/foo.dart'));
      log
          .loggerForStep('builder1', AssetId('pkg', 'lib/foo.dart'))
          .warning('Some builder warning.');

      // TODO(davidmorgan): set and use root package.
      expect(
        log.render(),
        padLinesRight('''
 --- build_runner lib/foo.dart
 <1s setup
 <1s builder1,  0%
       1 warning(s), latest: pkg|lib/foo.dart
       Some builder warning.
     builder2
     cleanup'''),
      );
    });

    test('build progress with builder errors', () {
      log.builders(['builder1', 'builder2'], {'builder1': 10, 'builder2': 15});
      log.progress(Progress.build('builder1', 'lib/foo.dart'));
      log
          .loggerForStep('builder1', AssetId('pkg', 'lib/foo.dart'))
          .severe('Some builder error.');

      // TODO(davidmorgan): set and use root package.
      expect(
        log.render(),
        padLinesRight('''
 --- build_runner lib/foo.dart
 <1s setup
 <1s builder1,  0%
       1 error(s), latest: pkg|lib/foo.dart
       Some builder error.
     builder2
     cleanup'''),
      );
    });

    test('complete build with no warnings or errors', () {
      log.progress(Progress.generateBuildScript);
      log.progress(Progress.compileBuildScript);
      log.progress(Progress.newAssetGraph);
      log.progress(Progress.initialBuildCleanup);
      log.progress(Progress.updateAssetGraph);

      log.builders(['builder1', 'builder2'], {'builder1': 10, 'builder2': 15});

      log.progress(Progress.build('builder1', 'lib/foo.dart'));
      log.progress(Progress.build('builder2', 'lib/foo.dart'));
      log.progress(Progress.writeAssetGraph);
      log.progress(Progress.done);

      expect(
        log.render(),
        padLinesRight('''
 --- build_runner
 <1s setup
 <1s builder1
 <1s builder2
 <1s cleanup'''),
      );
    });

    test('complete build with warnings and errors', () {
      log.builders(['builder1', 'builder2'], {'builder1': 10, 'builder2': 15});
      log.progress(Progress.build('builder1', 'lib/foo.dart'));
      log
          .loggerForStep('builder1', AssetId('pkg', 'lib/foo1.dart'))
          .warning('Some builder warning.');
      log
          .loggerForStep('builder1', AssetId('pkg', 'lib/foo2.dart'))
          .severe('Some builder error.');
      log.progress(Progress.build('builder2', 'lib/bar1.dart'));
      log
          .loggerForStep('builder2', AssetId('pkg', 'lib/bar1.dart'))
          .warning('Some other builder warning.');
      log
          .loggerForStep('builder2', AssetId('pkg', 'lib/bar2.dart'))
          .severe('Some other builder error.');
      log.progress(Progress.done);
      log.buildDone(true);

      // TODO(davidmorgan): set and use root package.
      expect(
        log.render(),
        padLinesRight('''
 --- build_runner
 <1s setup
 <1s builder1
 <1s builder2
 <1s cleanup
 === builder1 on pkg|lib/foo1.dart warnings
     Some builder warning.
 === builder1 on pkg|lib/foo2.dart errors
     Some builder error.
 === builder2 on pkg|lib/bar1.dart warnings
     Some other builder warning.
 === builder2 on pkg|lib/bar2.dart errors
     Some other builder error.
 --- SUCCESS'''),
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
