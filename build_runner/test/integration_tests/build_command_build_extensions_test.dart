// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Tags(['integration1'])
library;

import 'package:test/test.dart';

import '../common/common.dart';

void main() async {
  test('build command captures prints and throws in buildExtensions', () async {
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
  Map<String, List<String>> get buildExtensions {
    print('printed in buildExtensions');
    return {'.txt': ['.txt.copy']};
  }

  @override
  Future<void> build(BuildStep buildStep) async {
    await buildStep.writeAsString(
      buildStep.inputId.addExtension('.copy'),
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
      files: {'web/a.txt': 'a'},
    );

    // A print is logged at info level, so it's shown only with `--verbose`.
    var output = await tester.run(
      'root_pkg',
      'dart run build_runner build --force-jit',
    );
    expect(output, isNot(contains('printed in buildExtensions')));
    expect(tester.read('root_pkg/web/a.txt.copy'), 'a');

    output = await tester.run(
      'root_pkg',
      'dart run build_runner build --force-jit --verbose',
    );
    expect(output, contains('printed in buildExtensions'));

    // A throw is logged as an error, as for a throw in the builder factory.
    tester.update('builder_pkg/lib/builder.dart', (script) {
      return script.replaceAll(
        "print('printed in buildExtensions');",
        "throw StateError('thrown in buildExtensions');",
      );
    });
    output = await tester.run(
      'root_pkg',
      'dart run build_runner build --force-jit',
      expectExitCode: 78,
    );
    expect(output, contains('thrown in buildExtensions'));
  });
}
