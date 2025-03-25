// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:_test_common/common.dart';
import 'package:build/build.dart';
import 'package:build_runner_core/src/generate/build_result.dart';
import 'package:build_runner_core/src/generate/exceptions.dart';
import 'package:build_runner_core/src/package_graph/apply_builders.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

void main() {
  test('fail if an output is on disk and !deleteFilesByDefault', () async {
    expect(
      testPhases(
        [applyToRoot(TestBuilder())],
        {'a|lib/a.dart': '', 'a|lib/a.dart.copy': ''},
        packageGraph: buildPackageGraph({rootPackage('a'): []}),
        deleteFilesByDefault: false,
      ),
      throwsA(const TypeMatcher<CannotBuildException>()),
    );
  });

  test('should fail if a severe logged', () async {
    await testPhases(
      [applyToRoot(_LoggingBuilder(Level.SEVERE))],
      {'a|lib/a.dart': ''},
      packageGraph: buildPackageGraph({rootPackage('a'): []}),
      checkBuildStatus: true,
      status: BuildStatus.failure,
      outputs: {'a|lib/a.dart.empty': ''},
    );
  });

  test('should fail if a severe was logged on a previous build', () async {
    var packageGraph = buildPackageGraph({rootPackage('a'): []});
    var builder = _LoggingBuilder(Level.SEVERE);
    var builders = [applyToRoot(builder)];
    final result = await testPhases(
      builders,
      {'a|lib/a.dart': ''},
      packageGraph: packageGraph,
      checkBuildStatus: true,
      status: BuildStatus.failure,
      outputs: {'a|lib/a.dart.empty': ''},
    );
    await testPhases(
      builders,
      {},
      resumeFrom: result,
      packageGraph: packageGraph,
      checkBuildStatus: true,
      status: BuildStatus.failure,
      outputs: {},
    );
  });

  test(
    'should succeed if a severe log is fixed on a subsequent build',
    () async {
      var packageGraph = buildPackageGraph({rootPackage('a'): []});
      var builder = _LoggingBuilder(Level.SEVERE);
      var builders = [applyToRoot(builder)];
      final result = await testPhases(
        builders,
        {'a|lib/a.dart': ''},
        packageGraph: packageGraph,
        checkBuildStatus: true,
        status: BuildStatus.failure,
        outputs: {'a|lib/a.dart.empty': ''},
      );
      builder.level = Level.WARNING;
      await testPhases(
        builders,
        {'a|lib/a.dart': 'changed'},
        resumeFrom: result,
        packageGraph: packageGraph,
        checkBuildStatus: true,
        status: BuildStatus.success,
        outputs: {'a|lib/a.dart.empty': ''},
      );
    },
  );

  test('should fail if an exception is thrown', () async {
    await testPhases(
      [
        applyToRoot(
          TestBuilder(build: (_, _) => throw Exception('Some build failure')),
        ),
      ],
      {'a|lib/a.txt': ''},
      packageGraph: buildPackageGraph({rootPackage('a'): []}),
      status: BuildStatus.failure,
    );
  });

  test(
    'should throw an exception if a read is attempted on a failed file',
    () async {
      await testPhases(
        [
          applyToRoot(
            TestBuilder(
              buildExtensions: replaceExtension('.txt', '.failed'),
              build: (buildStep, _) async {
                await buildStep.writeAsString(
                  buildStep.inputId.changeExtension('.failed'),
                  'failed',
                );
                log.severe('Wrote an output then failed');
              },
            ),
          ),
          applyToRoot(
            TestBuilder(
              buildExtensions: replaceExtension('.txt', '.success'),
              build: expectAsync2((buildStep, _) async {
                // Attempts to read the file that came from a failing build step
                // and hides the exception.
                var failedFile = buildStep.inputId.changeExtension('.failed');
                await expectLater(
                  buildStep.readAsString(failedFile),
                  throwsA(anything),
                );
                await buildStep.writeAsString(
                  buildStep.inputId.changeExtension('.success'),
                  'success',
                );
              }),
            ),
          ),
        ],
        {'a|lib/a.txt': ''},
        packageGraph: buildPackageGraph({rootPackage('a'): []}),
        status: BuildStatus.failure,
      );
    },
  );
}

class _LoggingBuilder implements Builder {
  Level level;

  _LoggingBuilder(this.level);

  @override
  Future<void> build(BuildStep buildStep) async {
    log.log(level, buildStep.inputId.toString());
    await buildStep.canRead(buildStep.inputId);
    await buildStep.writeAsString(buildStep.inputId.addExtension('.empty'), '');
  }

  @override
  final buildExtensions = const {
    '.dart': ['.dart.empty'],
  };
}
