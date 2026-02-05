// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Tags(['integration4'])
library;

import 'package:io/io.dart';
import 'package:test/test.dart';

import '../common/common.dart';

void main() async {
  test('run command', () async {
    final pubspecs = await Pubspecs.load();
    final tester = BuildRunnerTester(pubspecs);

    tester.writePackage(
      name: 'builder_pkg',
      dependencies: ['build', 'build_runner'],
      files: {
        'build.yaml': '''
builders:
  test_builder:
    import: 'package:builder_pkg/builder.dart'
    builder_factories: ['testBuilderFactory']
    build_extensions: {'.txt': ['.txt.copy']}
    auto_apply: root_package
    build_to: source
''',
        'lib/builder.dart': '''
import 'package:build/build.dart';

Builder testBuilderFactory(BuilderOptions options) => TestBuilder();

class TestBuilder implements Builder {
  @override
  Map<String, List<String>> get buildExtensions => {'.dart': ['.copy.dart']};

  @override
  Future<void> build(BuildStep buildStep) async {
    buildStep.writeAsString(
        buildStep.inputId.changeExtension('.copy.dart'),
        await buildStep.readAsString(buildStep.inputId),
    );
  }
}
''',
      },
    );
    tester.writePackage(
      name: 'root_pkg',
      dependencies: ['build_runner'],
      pathDependencies: ['builder_pkg'],
      files: {
        'bin/main.txt': '',
        'bin/main.dart': r'''
import 'dart:io';

void main(List<String> args) {
  print('script is running');
  print('args: $args');
  if (args.contains('throw')) {
    throw ArgumentError('asked to throw');
  }
}
''',
      },
    );

    // Message when script to run is omitted.
    var output = await tester.run(
      'root_pkg',
      'dart run build_runner run',
      expectExitCode: ExitCode.usage.code,
    );
    expect(output, contains('Must specify an executable to run.'));

    // Message when script to run does not end `.dart`.
    output = await tester.run(
      'root_pkg',
      'dart run build_runner run bin/main.txt.copy',
      expectExitCode: ExitCode.usage.code,
    );
    expect(output, contains('is not a valid Dart file'));

    // Message output when script to run is missing.
    output = await tester.run(
      'root_pkg',
      'dart run build_runner run bin/nonexistent.dart',
      expectExitCode: ExitCode.ioError.code,
    );
    expect(
      output,
      contains(
        'Could not spawn isolate. Ensure that your file is in a valid '
        'directory',
      ),
    );

    // Run script as it was copied by the build.
    output = await tester.run(
      'root_pkg',
      'dart run build_runner run bin/main.copy.dart',
    );
    expect(output, contains('script is running'));

    // Works with --output.
    output = await tester.run(
      'root_pkg',
      'dart run build_runner run bin/main.copy.dart --output build',
    );
    expect(output, contains('script is running'));

    // Args are passed to the script.
    output = await tester.run(
      'root_pkg',
      'dart run build_runner run bin/main.copy.dart -- a b c',
    );
    expect(output, contains('script is running'));
    expect(output, contains('args: [a, b, c]'));

    // Script error exit is handled.
    output = await tester.run(
      'root_pkg',
      'dart run build_runner run bin/main.copy.dart -- throw',
      expectExitCode: 1,
    );
    expect(output, contains('Unhandled error from script:'));
    expect(output, contains('asked to throw'));
    // Stack trace mentions the script path.
    expect(output, contains('bin/main.copy.dart'));
  });
}
