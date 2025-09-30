// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Tags(['integration1'])
library;

import 'package:build_runner/src/internal.dart';
import 'package:io/io.dart';
import 'package:test/test.dart';

import '../common/common.dart';

void main() async {
  test('build command config validation', () async {
    final pubspecs = await Pubspecs.load();
    final tester = BuildRunnerTester(pubspecs);

    tester.writePackage(
      name: 'root_pkg',
      dependencies: ['build_runner'],
      files: {
        'build.yaml': r'''
targets:
  $default:
    builders:
      bad:builder:
        enabled: true
''',
      },
    );

    var output = await tester.run('root_pkg', 'dart run build_runner build');
    expect(
      output,
      contains(
        'Ignoring options for unknown builder `bad:builder` '
        'in target `root_pkg:root_pkg`.',
      ),
    );

    tester.write('root_pkg/build.yaml', r'''
global_options:
  bad:builder:
    options: {}
''');
    output = await tester.run('root_pkg', 'dart run build_runner build');
    expect(
      output,
      contains('Ignoring `global_options` for unknown builder `bad:builder`.'),
    );

    tester.delete('root_pkg/build.yaml');
    output = await tester.run(
      'root_pkg',
      'dart run build_runner build --define=bad:key=foo=bar',
    );
    expect(
      output,
      contains('Ignoring options overrides for unknown builder `bad:key`.'),
    );

    // Compile errors caused by config errors.
    tester.write('root_pkg/build.yaml', r'''
builders:
  test_builder:
    import: 'missing_builder.dart'
    builder_factories: ['missingFactory']
    build_extensions: {'.txt': ['.txt.copy']}
    auto_apply: root_package
    build_to: source
''');
    output = await tester.run(
      'root_pkg',
      'dart run build_runner build',
      expectExitCode: ExitCode.config.code,
    );
    expect(output, contains("Error when reading 'missing_builder.dart'"));
    expect(output, contains("Undefined name 'missingFactory'"));

    // A relative import is handled correctly.
    tester.write('root_pkg/build.yaml', r'''
builders:
  test_builder:
    import: 'tool/missing_builder.dart'
    builder_factories: ['missingFactory']
    build_extensions: {'.txt': ['.txt.copy']}
    auto_apply: root_package
    build_to: source
''');
    output = await tester.run(
      'root_pkg',
      'dart run build_runner build',
      expectExitCode: ExitCode.config.code,
    );
    expect(
      tester.read('root_pkg/$entrypointScriptPath'),
      contains("import '../../../tool/missing_builder.dart'"),
    );
  });
}
