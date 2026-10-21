// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Tags(['integration3'])
library;

import 'package:build_runner/src/logging/build_log.dart';
import 'package:test/test.dart';

import '../common/common.dart';

void main() async {
  test('watch command build script changes', () async {
    final pubspecs = await Pubspecs.load();
    final tester = BuildRunnerTester(pubspecs);

    // A builder with two factories: the first writes `first_factory`, the
    // second writes `second_factory`.
    tester.writeFixturePackage(FixturePackages.copyBuilder());
    tester.write('builder_pkg/lib/builder.dart', '''
import 'package:build/build.dart';
Builder testBuilderFactory(BuilderOptions options)
    => TestBuilder('first_factory');
Builder testBuilderFactory2(BuilderOptions options)
    => TestBuilder('second_factory');
class TestBuilder implements Builder {
  final String output;
  TestBuilder(this.output);
  Map<String, List<String>> get buildExtensions => {'.txt': ['.txt.copy']};
  Future<void> build(BuildStep buildStep) async {
    buildStep.writeAsString(buildStep.inputId.addExtension('.copy'), output);
  }
}
''');
    tester.writePackage(
      name: 'root_pkg',
      dependencies: ['build_runner'],
      pathDependencies: ['builder_pkg'],
      files: {'web/a.txt': 'a'},
    );

    // Watch and initial build.
    final watch = await tester.start(
      'root_pkg',
      'dart run build_runner watch --force-jit',
    );
    await watch.expect(BuildLog.successPattern);
    expect(tester.read('root_pkg/web/a.txt.copy'), 'first_factory');

    // Builder config change in dependency that changes the build script by
    // changing the factory to `testBuilderFactory2`.
    tester.write('builder_pkg/build.yaml', '''
builders:
  test_builder:
    import: 'package:builder_pkg/builder.dart'
    builder_factories: ['testBuilderFactory2']
    build_extensions: {'.txt': ['.txt.copy']}
    auto_apply: root_package
    build_to: source
''');
    await watch.expect(BuildLog.successPattern);
    expect(tester.read('root_pkg/web/a.txt.copy'), 'second_factory');

    // Builder config change in dependency that changes the build script to
    // something broken.
    tester.update(
      'builder_pkg/build.yaml',
      (yaml) =>
          '''
$yaml
  missing_builder:
    import: 'package:builder_pkg/builder.dart'
    builder_factories: ['missingBuilderFactory']
    build_extensions: {'.txt': ['']}
''',
    );
    await watch.expect('missingBuilderFactory');
    await watch.expect(
      'Failed to compile build script. '
      'Check builder definitions and generated script '
      '.dart_tool/build/entrypoint/build.dart. '
      'Retrying.',
    );

    // The first build after retry is marked as a new build.
    await watch.expect('Starting build #4');
    // But the next identical build failure is not logged as a new build.
    final block = await watch.expectAndGetBlock('compiling builders');
    expect(block, isNot(contains('Starting build')));

    // Restore the correct build script and it gets compiled and runs.
    tester.write('builder_pkg/build.yaml', '''
builders:
  test_builder:
    import: 'package:builder_pkg/builder.dart'
    builder_factories: ['testBuilderFactory2']
    build_extensions: {'.txt': ['.txt.copy']}
    auto_apply: root_package
    build_to: source
''');
    await watch.expect(BuildLog.successPattern);
  });
}
