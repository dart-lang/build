// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Tags(['integration2'])
library;

import 'package:test/test.dart';

import '../common/common.dart';

void main() async {
  test('build command AOT', () async {
    final pubspecs = await Pubspecs.load();
    final tester = BuildRunnerTester(pubspecs);

    // Basic AOT build and rebuild on change.
    tester.writeFixturePackage(FixturePackages.copyBuilder());
    tester.writePackage(
      name: 'root_pkg',
      dependencies: ['build_runner'],
      pathDependencies: ['builder_pkg'],
      files: {'web/a.txt': 'a'},
    );

    // First build.
    var output = await tester.run(
      'root_pkg',
      'dart run build_runner build --force-aot',
    );
    expect(output, contains('with build_runner/aot'));
    expect(tester.read('root_pkg/web/a.txt.copy'), 'a');

    // With no changes, no rebuild.
    output = await tester.run(
      'root_pkg',
      'dart run build_runner build --force-aot',
    );
    expect(output, contains('wrote 0 outputs'));

    // Change the build script, rebuilds.
    tester.update('builder_pkg/lib/builder.dart', (script) => '$script\n');
    output = await tester.run(
      'root_pkg',
      'dart run build_runner build --force-aot',
    );
    expect(output, contains('wrote 1 output'));

    // Builder using `dart:mirrors`.
    tester.writePackage(
      name: 'builder_pkg',
      dependencies: ['build', 'build_runner'],
      files: {
        'build.yaml': '''
builders:
  test_builder:
    import: 'package:builder_pkg/builder.dart'
    builder_factories: ['testBuilderFactory']
    build_extensions: {'.txt': ['.g.dart']}
    auto_apply: root_package
    build_to: source
''',
        'lib/builder.dart': '''
import 'dart:mirrors';
import 'package:build/build.dart';

Builder testBuilderFactory(BuilderOptions options) => TestBuilder();

class TestBuilder implements Builder {
  @override
  Map<String, List<String>> get buildExtensions => {'.txt': ['.g.dart']};

  @override
  Future<void> build(BuildStep buildStep) async {
    print(currentMirrorSystem());
  }
}
''',
      },
    );
    tester.writePackage(
      name: 'root_pkg',
      dependencies: ['build_runner'],
      pathDependencies: ['builder_pkg'],
      files: {'lib/a.txt': 'a'},
    );

    // Fall back to JIT and succeeds.
    output = await tester.run('root_pkg', 'dart run build_runner build');
    expect(
      output,
      contains('AOT compilation failed due to dart:mirrors usage.'),
    );
    expect(output, contains('Built with build_runner/jit'));

    // With `--force-aot`, fails.
    output = await tester.run(
      'root_pkg',
      'dart run build_runner build --force-aot',
      expectExitCode: 78,
    );
    expect(
      output,
      contains('Not falling back to JIT compilation due to --force-aot'),
    );
  });
}
