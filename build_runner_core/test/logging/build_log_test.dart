// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*import 'package:build/build.dart';
import 'package:build_runner_core/src/logging/ansi_buffer.dart';
import 'package:build_runner_core/src/logging/build_log.dart';
import 'package:test/test.dart';

void main() {
  group('BuildLog', () {
    setUp(buildLog.reset);

    List<String> render() =>
        buildLog.render().map(AnsiBuffer.removeAnsi).toList();

    test('initial display', () {
      expect(
        render(),
        padLinesRight('''
 --- build_runner'''),
      );
    });

    test('initial display, build mode', () {
      buildLog.start(BuildLogMode.build);
      expect(
        render(),
        padLinesRight('''
 --- build_runner
 <1s setup,  0%'''),
      );
    });

    test('setup', () {
      buildLog.start(BuildLogMode.build);
      buildLog.progress(Progress.generateBuildScript);
      buildLog.progress(Progress.compileBuildScript);
      expect(
        render(),
        padLinesRight('''
 --- build_runner compile build script
 <1s setup, 25%'''),
      );
    });

    test('setup note wraps at 80 cols', () {
      buildLog.start(BuildLogMode.build);
      buildLog.progress(Progress('setup', 1, '0123456789' * 8));
      expect(
        render(),
        padLinesRight('''
 --- build_runner 01234567890123456789012345678901234567890123456789012345678901
                  234567890123456789 
 <1s setup, 12%'''),
      );
    });

    test('build progress with no warnings or errors', () {
      buildLog.start(BuildLogMode.build);
      buildLog.builders({'builder1': 10, 'builder2': 15});

      buildLog.progress(Progress.build('builder1', 'lib/foo.dart'));

      expect(
        render(),
        padLinesRight('''
 --- build_runner lib/foo.dart
 <1s setup
 <1s builder1,  0%
     builder2
     cleanup'''),
      );
    });

    test('build progress with builder warnings', () {
      buildLog.start(BuildLogMode.build);
      buildLog.builders({'builder1': 10, 'builder2': 15});
      buildLog.progress(Progress.build('builder1', 'lib/foo.dart'));
      buildLog
          .loggerForStep('builder1', AssetId('pkg', 'lib/foo.dart'))
          .warning('Some builder warning.');

      // TODO(davidmorgan): set and use root package.
      expect(
        render(),
        padLinesRight('''
 --- build_runner lib/foo.dart
 <1s setup
 <1s builder1,  0%
       1 warning(s), latest: lib/foo.dart
       Some builder warning.
     builder2
     cleanup'''),
      );
    });

    test('build progress with builder errors', () {
      buildLog.start(BuildLogMode.build);
      buildLog.builders({'builder1': 10, 'builder2': 15});
      buildLog.progress(Progress.build('builder1', 'lib/foo.dart'));
      buildLog
          .loggerForStep('builder1', AssetId('pkg', 'lib/foo.dart'))
          .severe('Some builder error.');

      // TODO(davidmorgan): set and use root package.
      expect(
        render(),
        padLinesRight('''
 --- build_runner lib/foo.dart
 <1s setup
 <1s builder1,  0%
       1 error(s), latest: lib/foo.dart
       Some builder error.
     builder2
     cleanup'''),
      );
    });

    test('build progress with builder info is off by default', () {
      buildLog.start(BuildLogMode.build);
      buildLog.builders({'builder1': 10, 'builder2': 15});
      buildLog.progress(Progress.build('builder1', 'lib/foo.dart'));
      buildLog
          .loggerForStep('builder1', AssetId('pkg', 'lib/foo.dart'))
          .info('Some builder info.');

      // TODO(davidmorgan): set and use root package.
      expect(
        render(),
        padLinesRight('''
 --- build_runner lib/foo.dart
 <1s setup
 <1s builder1,  0%
     builder2
     cleanup'''),
      );
    });

    test('build progress with builder info is on in verbose mode', () {
      buildLog.start(BuildLogMode.build);
      buildLog.configuration = buildLog.configuration.rebuild((b) {
        b.verbose = true;
      });

      buildLog.builders({'builder1': 10, 'builder2': 15});
      buildLog.progress(Progress.build('builder1', 'lib/foo.dart'));
      buildLog
          .loggerForStep('builder1', AssetId('pkg', 'lib/foo.dart'))
          .info('Some builder info.');

      // TODO(davidmorgan): set and use root package.
      expect(
        render(),
        padLinesRight('''
 --- build_runner lib/foo.dart
 <1s setup
 <1s builder1,  0%
       1 info(s), latest: pkg|lib/foo.dart
       Some builder info.
     builder2
     cleanup'''),
      );
    });

    test('complete build with no warnings or errors', () {
      buildLog.start(BuildLogMode.build);
      buildLog.progress(Progress.generateBuildScript);
      buildLog.progress(Progress.compileBuildScript);
      buildLog.progress(Progress.newAssetGraph);
      buildLog.progress(Progress.initialBuildCleanup);
      buildLog.progress(Progress.updateAssetGraph);

      buildLog.builders({'builder1': 10, 'builder2': 15});

      buildLog.progress(Progress.build('builder1', 'lib/foo.dart'));
      buildLog.progress(Progress.build('builder2', 'lib/foo.dart'));
      buildLog.progress(Progress.writeAssetGraph);
      buildLog.progress(Progress.done);

      expect(
        render(),
        padLinesRight('''
 --- build_runner
 <1s setup
 <1s builder1
 <1s builder2
 <1s cleanup'''),
      );
    });

    test('complete build with warnings and errors', () {
      buildLog.start(BuildLogMode.build);
      buildLog.builders({'builder1': 10, 'builder2': 15});
      buildLog.progress(Progress.build('builder1', 'lib/foo.dart'));
      buildLog
          .loggerForStep('builder1', AssetId('pkg', 'lib/foo.dart'))
          .warning('Some builder warning.');
      buildLog
          .loggerForStep('builder1', AssetId('pkg', 'lib/foo.dart'))
          .severe('Some builder error.');
      buildLog.progress(Progress.build('builder2', 'lib/bar1.dart'));
      buildLog
          .loggerForStep('builder2', AssetId('pkg', 'lib/foo.dart'))
          .warning('Some other builder warning.');
      buildLog
          .loggerForStep('builder2', AssetId('pkg', 'lib/foo.dart'))
          .severe('Some other builder error.');
      buildLog.progress(Progress.done);
      buildLog.buildDone(result: true, outputs: 1);

      // TODO(davidmorgan): set and use root package.
      expect(
        render(),
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

List<String> padLinesRight(String output) {
  final result = <String>[];
  for (final line in output.split('\n')) {
    result.add(line.padRight(80));
  }
  return result;
}
*/
