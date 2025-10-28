// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Tags(['integration3'])
library;

import 'package:build_runner/src/logging/build_log.dart';
import 'package:test/test.dart';

import '../common/common.dart';

void main() async {
  test('watch command', () async {
    final pubspecs = await Pubspecs.load();
    final tester = BuildRunnerTester(pubspecs);

    tester.writeFixturePackage(FixturePackages.copyBuilder());
    tester.writePackage(
      name: 'root_pkg',
      dependencies: ['build_runner'],
      pathDependencies: ['builder_pkg', 'other_pkg'],
      files: {'web/a.txt': 'a'},
    );
    tester.writePackage(
      name: 'other_pkg',
      dependencies: ['build_runner'],
      pathDependencies: ['builder_pkg'],
      files: {},
    );

    // Watch and initial build.
    var watch = await tester.start('root_pkg', 'dart run build_runner watch');
    await watch.expect(BuildLog.successPattern);
    expect(tester.read('root_pkg/web/a.txt.copy'), 'a');

    // File change.
    tester.write('root_pkg/web/a.txt', 'updated');
    await watch.expect(BuildLog.successPattern);
    expect(tester.read('root_pkg/web/a.txt.copy'), 'updated');

    // File rewrite without change.
    tester.write('root_pkg/web/a.txt', 'updated');
    await watch.expectNoOutput(const Duration(seconds: 1));

    // State on disk is updated so `build` knows to do nothing.
    var output = await tester.run('root_pkg', 'dart run build_runner build');
    expect(output, contains('wrote 0 outputs'));

    // New file.
    tester.write('root_pkg/web/b.txt', 'b');
    await watch.expect(BuildLog.successPattern);
    expect(tester.read('root_pkg/web/b.txt.copy'), 'b');

    // State on disk is updated so `build` knows to do nothing.
    output = await tester.run('root_pkg', 'dart run build_runner build');
    expect(output, contains('wrote 0 outputs'));

    // Deleted file.
    tester.delete('root_pkg/web/b.txt');
    await watch.expect(BuildLog.successPattern);
    expect(tester.read('root_pkg/web/b.txt.copy'), null);

    // Deleted output.
    tester.delete('root_pkg/web/a.txt.copy');
    await watch.expect('wrote 1 output');
    expect(tester.read('root_pkg/web/a.txt.copy'), 'updated');

    // File change during build.
    tester.write('root_pkg/web/a.txt', 'a');
    await watch.expect('builder_pkg:test_builder');
    tester.write('root_pkg/web/a.txt', 'updated');
    await watch.expect(BuildLog.successPattern);
    expect(tester.read('root_pkg/web/a.txt.copy'), 'a');
    await watch.expect(BuildLog.successPattern);
    expect(tester.read('root_pkg/web/a.txt.copy'), 'updated');

    // Builder change to one that writes output from config key `output` if
    // present or writes `hardcoded` if not. There is a second factory that
    // ignores the config and writes `second_factory`.
    tester.write('builder_pkg/lib/builder.dart', '''
import 'package:build/build.dart';
Builder testBuilderFactory(BuilderOptions options)
    => TestBuilder(options.config['output'] ?? 'hardcoded');
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
    await watch.expect(BuildLog.successPattern);
    expect(tester.read('root_pkg/web/a.txt.copy'), 'hardcoded');

    // State on disk is updated so `build` knows to do nothing.
    output = await tester.run('root_pkg', 'dart run build_runner build');
    expect(output, contains('wrote 0 outputs'));

    // Builder config change, add a file but it has no effect.
    tester.write('root_pkg/build.yaml', '# new file, nothing here');
    await watch.expect('wrote 0 outputs');

    // Builder config change, update a file to change options.
    tester.write('root_pkg/build.yaml', r'''
targets:
  $default:
    builders:
      builder_pkg:test_builder:
        options:
          output: "configured"
''');
    await watch.expect('wrote 1 output');
    expect(tester.read('root_pkg/web/a.txt.copy'), 'configured');

    // Builder config change in dependency but it has no effect.
    tester.write('other_pkg/build.yaml', '# new file, nothing here');
    await watch.expect('wrote 0 outputs');

    // Builder config change in root overriding dependency but it has no effect.
    tester.write('root_pkg/other_pkg.build.yaml', '# new file, nothing here');
    await watch.expect('wrote 0 outputs');

    // State on disk is updated so `build` knows to do nothing.
    output = await tester.run('root_pkg', 'dart run build_runner build');
    expect(output, contains('wrote 0 outputs'));

    // No-op change to `package_config.json` causes a build.
    tester.update(
      'root_pkg/.dart_tool/package_config.json',
      (script) => '$script\n',
    );
    await watch.expect(BuildLog.successPattern);
    await watch.kill();

    // Now with --output.
    watch = await tester.start(
      'root_pkg',
      'dart run build_runner watch --output web:build',
    );
    await watch.expect(BuildLog.successPattern);
    expect(tester.read('root_pkg/build/a.txt'), 'updated');
    expect(tester.read('root_pkg/build/a.txt.copy'), 'configured');

    // Changed inputs and outputs are written to output directory.
    tester.write('root_pkg/web/a.txt', 'a');
    await watch.expect(BuildLog.successPattern);
    expect(tester.read('root_pkg/build/a.txt'), 'a');
    expect(tester.read('root_pkg/build/a.txt.copy'), 'configured');

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
    expect(tester.read('root_pkg/build/a.txt.copy'), 'second_factory');

    // Builder config change in dependency that changes the build script to
    // something broken.
    tester.update(
      'builder_pkg/build.yaml',
      (yaml) => '''
$yaml
  missing_builder:
    import: 'package:builder_pkg/builder.dart'
    builder_factories: ['missingBuilderFactory']
    build_extensions: {'.txt': ['']}
''',
    );
    await watch.expect(
      'Failed to compile build script. '
      'Check builder definitions and generated script '
      '.dart_tool/build/entrypoint/build.dart. '
      'Retrying.',
    );

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
