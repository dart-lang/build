// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Tags(['integration1'])
library;

import 'package:test/test.dart';

import '../common/common.dart';

void main() async {
  test('build command --define', () async {
    final pubspecs = await Pubspecs.load();
    final tester = BuildRunnerTester(pubspecs);

    tester.writePackage(
      name: 'builder_pkg',
      dependencies: ['build', 'build_runner'],
      files: {
        'build.yaml': r'''
builders:
  test_builder:
    import: 'package:builder_pkg/builder.dart'
    builder_factories: ['testBuilderFactory']
    build_extensions: {'.txt': ['.txt.copy']}
    auto_apply: root_package
    build_to: source
    defaults:
      options:
        copy_from: root_pkg|web/a.txt
      dev_options:
        extra_content: "(default dev)"
      release_options:
        extra_content: "(default release)"
''',
        'lib/builder.dart': '''
import 'package:build/build.dart';

Builder testBuilderFactory(BuilderOptions options) =>
    TestBuilder(
        AssetId.parse(options.config['copy_from'] as String),
        options.config['extra_content'] as String? ?? '');

class TestBuilder implements Builder {
  final AssetId copyFrom;
  final String extraContent;

  TestBuilder(this.copyFrom, this.extraContent);

  @override
  Map<String, List<String>> get buildExtensions => {'.txt': ['.txt.copy']};

  @override
  Future<void> build(BuildStep buildStep) async {
    buildStep.writeAsString(
        buildStep.inputId.addExtension('.copy'),
        await buildStep.readAsString(copyFrom) + extraContent,
    );
  }
}''',
      },
    );
    tester.writePackage(
      name: 'root_pkg',
      dependencies: ['build_runner'],
      pathDependencies: ['builder_pkg'],
      files: {'web/a.txt': 'a', 'web/b.txt': 'b'},
    );

    // Default dev build.
    await tester.run('root_pkg', 'dart run build_runner build --force-jit');
    expect(tester.read('root_pkg/web/a.txt.copy'), 'a(default dev)');

    // Default release build.
    await tester.run(
      'root_pkg',
      'dart run build_runner build --force-jit --release',
    );
    expect(tester.read('root_pkg/web/a.txt.copy'), 'a(default release)');

    // Configure via `build.yaml`.
    tester.write('root_pkg/build.yaml', r'''
targets:
  $default:
    builders:
      builder_pkg:test_builder:
        options:
          copy_from: root_pkg|web/b.txt
        dev_options:
          extra_content: "(yaml dev)"
        release_options:
          extra_content: "(yaml release)"
''');
    await tester.run('root_pkg', 'dart run build_runner build --force-jit');
    expect(tester.read('root_pkg/web/a.txt.copy'), 'b(yaml dev)');

    await tester.run(
      'root_pkg',
      'dart run build_runner build --force-jit --release',
    );
    expect(tester.read('root_pkg/web/a.txt.copy'), 'b(yaml release)');

    // Override with `--define`.
    await tester.run(
      'root_pkg',
      'dart run build_runner build --force-jit '
          '--define=builder_pkg:test_builder=copy_from=root_pkg|web/a.txt',
    );
    expect(tester.read('root_pkg/web/a.txt.copy'), 'a(yaml dev)');

    // Override with `--define` and `--release`.
    await tester.run(
      'root_pkg',
      'dart run build_runner build --force-jit --release '
          '--define=builder_pkg:test_builder=copy_from=root_pkg|web/a.txt',
    );
    expect(tester.read('root_pkg/web/a.txt.copy'), 'a(yaml release)');

    // Override with global options.
    tester.write('root_pkg/build.yaml', r'''
targets:
  $default:
    builders:
      builder_pkg:test_builder:
        options:
          copy_from: root_pkg|web/b.txt
        dev_options:
          extra_content: "(yaml dev)"
        release_options:
          extra_content: "(yaml release)"

global_options:
  builder_pkg:test_builder:
    options:
      extra_content: "(global)"
''');
    await tester.run('root_pkg', 'dart run build_runner build --force-jit');
    expect(tester.read('root_pkg/web/a.txt.copy'), 'b(global)');

    // Change to a workspace.
    tester.writePackage(
      name: 'root_pkg',
      dependencies: ['build_runner'],
      pathDependencies: ['builder_pkg'],
      files: {},
      inWorkspace: true,
    );
    tester.writeWorkspacePubspec(packages: ['root_pkg']);

    // Build with --workspace. Package options from `root_pkg/build.yaml`
    // still apply, but global options from `root_pkg/build.yaml` don't.
    await tester.run('', 'dart run build_runner build --force-jit --workspace');
    expect(tester.read('root_pkg/web/a.txt.copy'), 'b(yaml dev)');

    // Global options from workspace root `build.yaml` are used.
    tester.write('build.yaml', r'''
global_options:
  builder_pkg:test_builder:
    options:
      extra_content: "(workspace global)"
''');
    await tester.run('', 'dart run build_runner build --force-jit --workspace');
    expect(tester.read('root_pkg/web/a.txt.copy'), 'b(workspace global)');

    // Global options `runs_before` from workspace root `build.yaml` are used.
    tester.writePackage(
      name: 'pkg_a',
      files:
          FixturePackages.copyBuilder(
            packageName: 'pkg_a',
            outputExtension: '.a',
          ).files,
      dependencies: ['build', 'build_runner'],
      inWorkspace: true,
    );
    tester.writePackage(
      name: 'pkg_b',
      files:
          FixturePackages.copyBuilder(
            packageName: 'pkg_b',
            outputExtension: '.b',
          ).files,
      dependencies: ['build', 'build_runner'],
      inWorkspace: true,
    );
    tester.writePackage(
      name: 'root_pkg',
      dependencies: ['build_runner'],
      pathDependencies: ['pkg_a', 'pkg_b'],
      files: {'web/a.txt': 'a'},
      inWorkspace: true,
    );
    tester.writeWorkspacePubspec(packages: ['root_pkg', 'pkg_a', 'pkg_b']);

    // `pkg_a:test_builder` runs first.
    tester.write('build.yaml', r'''
global_options:
  pkg_a:test_builder:
    runs_before: ['pkg_b:test_builder']
''');
    // Run order can be determined by which shows first in the log.
    var output = await tester.run(
      '',
      'dart run build_runner build --force-jit --workspace',
    );
    expect(
      output.indexOf('pkg_a:test_builder'),
      lessThan(output.indexOf('pkg_b:test_builder')),
    );

    // `pkg_b:test_builder` runs first.
    tester.write('build.yaml', r'''
global_options:
  pkg_b:test_builder:
    runs_before: ['pkg_a:test_builder']
''');
    // Now they show in the reverse order in the log.
    output = await tester.run(
      '',
      'dart run build_runner build --force-jit --workspace',
    );
    expect(
      output.indexOf('pkg_a:test_builder'),
      greaterThan(output.indexOf('pkg_b:test_builder')),
    );
  });
}
