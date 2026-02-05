// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Tags(['integration3'])
library;

import 'package:test/test.dart';

import '../common/common.dart';

void main() async {
  test('build with resolution', () async {
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
    build_extensions: {'.dart': ['.g.dart']}
    auto_apply: root_package
    build_to: source
''',
        'lib/builder.dart': '''
import 'package:build/build.dart';

Builder testBuilderFactory(BuilderOptions options) => TestBuilder();

class TestBuilder implements Builder {
  @override
  Map<String, List<String>> get buildExtensions => {'.dart': ['.g.dart']};

  @override
  Future<void> build(BuildStep buildStep) async {
    await buildStep.inputLibrary;
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
        'lib/a.dart': '''
import 'missing_import.dart';
syntax error
''',
      },
    );

    // Syntax error.
    var output = await tester.run(
      'root_pkg',
      'dart run build_runner build',
      expectExitCode: 1,
    );
    expect(output, contains("Expected to find ';'"));

    // Unreadable inputs are allowed.
    tester.write('root_pkg/lib/a.dart', '''
import 'missing_import.dart';
''');
    output = await tester.run('root_pkg', 'dart run build_runner build');

    // Unreadable inputs in previousd build do not break incremental build.
    tester.update('root_pkg/lib/a.dart', (script) => '$script\n');
    output = await tester.run('root_pkg', 'dart run build_runner build');
  });
}
