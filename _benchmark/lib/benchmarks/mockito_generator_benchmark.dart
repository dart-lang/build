// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../benchmark.dart';
import '../config.dart';

/// Benchmark with one trivial service class and one test per library.
///
/// Each test creates a mock of only its corresponding service class, so
/// a test uses exactly one mock.
///
/// There is one large library cycle due to `app.dart` which depends on
/// everything and is depended on by everything.
class MockitoGeneratorBenchmark implements Benchmark {
  const MockitoGeneratorBenchmark();

  @override
  void create(RunConfig config) {
    final workspace = config.workspace;
    final size = config.size;

    // TODO(davidmorgan): add a way to pick `build` and generator versions.
    workspace.write(
      'pubspec.yaml',
      source: '''
name: ${workspace.name}
publish_to: none

environment:
  sdk: ^3.6.0

dependencies:
  mockito: any

dev_dependencies:
  build_runner: any

${config.dependencyOverrides}
''',
    );

    workspace.write(
      'lib/app.dart',
      source: '''
/// ignore_for_file: unused_import
/// CACHEBUSTER
''',
    );

    for (var testNumber = 0; testNumber != size; ++testNumber) {
      final testLines = [
        '// ignore_for_file: unused import',
        '// CACHEBUSTER',
        "import 'package:mockito/annotations.dart';",
      ];
      final libraryName = Benchmarks.libraryName(
        testNumber,
        benchmarkSize: size,
      );
      testLines.add("import 'package:${workspace.name}/$libraryName';");
      testLines.add('@GenerateNiceMocks([');
      testLines.add('MockSpec<Service$testNumber>(),');
      testLines.add('])');
      testLines.add("import 'some_test.mocks.dart';");

      final testName = Benchmarks.testName(testNumber, benchmarkSize: size);
      workspace.write(
        'test/$testName',
        source: testLines.map((l) => '$l\n').join(''),
      );
    }

    for (var libraryNumber = 0; libraryNumber != size; ++libraryNumber) {
      final libraryName = Benchmarks.libraryName(
        libraryNumber,
        benchmarkSize: size,
      );
      final importNames = config.shape.importNames(
        libraryNumber,
        benchmarkSize: size,
      );
      workspace.write(
        'lib/$libraryName',
        source: '''
// ignore_for_file: unused_import
${[for (final importName in importNames) "import '$importName';"].join('\n')}

class Service$libraryNumber {
  void doSomething(int value) {}
}
''',
      );
    }
  }
}
