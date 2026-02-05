// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Tags(['integration3'])
library;

import 'package:test/test.dart';

import '../common/common.dart';

void main() async {
  test('build command workspace', () async {
    final pubspecs = await Pubspecs.load();
    final tester = BuildRunnerTester(pubspecs);

    tester.writeFixturePackage(
      FixturePackages.copyBuilder(packageName: 'builder_pkg'),
    );
    tester.writeFixturePackage(
      FixturePackages.copyBuilder(
        packageName: 'cache_builder_pkg',
        buildToCache: true,
        applyToAllPackages: true,
        outputExtension: '.hidden',
      ),
    );
    // Workspace package with direct dependency on builder_pkg and
    // cache_builder_pkg.
    tester.writePackage(
      name: 'p1',
      dependencies: ['build_runner'],
      pathDependencies: ['builder_pkg', 'cache_builder_pkg'],
      files: {'lib/p1.txt': '1'},
      inWorkspace: true,
    );
    tester.write('pubspec.yaml', '''
name: workspace
environment:
  sdk: ^3.5.0
workspace: [p1]
''');

    // Run without --workspace in p1, builders apply.
    await tester.run('p1', 'dart run build_runner build');
    expect(tester.read('p1/lib/p1.txt.copy'), '1');
    expect(
      tester.read('p1/.dart_tool/build/generated/p1/lib/p1.txt.hidden'),
      '1',
    );

    // Run with --workspace in p1, builders apply, logs with package name.
    tester.write('p1/lib/p1.txt', '2');
    expect(
      await tester.run('p1', 'dart run build_runner build --workspace'),
      contains('on 1 input; p1|lib/p1.txt'),
    );
    expect(tester.read('p1/lib/p1.txt.copy'), '2');
    // Output is now under the workspace root.
    expect(tester.read('.dart_tool/build/generated/p1/lib/p1.txt.hidden'), '2');

    // Run with --workspace in workspace root, builders apply.
    tester.write('p1/lib/p1.txt', '3');
    expect(
      await tester.run('', 'dart run build_runner build --workspace'),
      contains('on 1 input; p1|lib/p1.txt'),
    );
    expect(tester.read('p1/lib/p1.txt.copy'), '3');
    expect(tester.read('.dart_tool/build/generated/p1/lib/p1.txt.hidden'), '3');

    // Add a package to the workspace that has no dependency, direct or
    // transitive, on `build_runner` or `builder_pkg`.
    tester.writePackage(
      name: 'p2',
      files: {'lib/p2.txt': '1'},
      inWorkspace: true,
    );
    tester.write('pubspec.yaml', '''
name: workspace
environment:
  sdk: ^3.5.0
workspace: [p1, p2]
''');

    // Builders do not apply.
    await tester.run('', 'dart run build_runner build --workspace');
    expect(tester.read('p2/lib/p2.txt.copy'), null);
    expect(
      tester.read('.dart_tool/build/generated/p2/lib/p2.txt.hidden'),
      null,
    );

    // Add a package to the workspace that has a transitive but not direct
    // dependency on `builder_pkg` and `cache_builder_pkg` via `p1`.
    tester.writePackage(
      name: 'p3',
      workspaceDependencies: ['p1'],
      files: {'lib/p3.txt': '1'},
      inWorkspace: true,
    );
    tester.write('pubspec.yaml', '''
name: workspace
environment:
  sdk: ^3.5.0
workspace: [p1, p2, p3]
''');

    // Builders run.
    await tester.run('p3', 'dart run build_runner build --workspace');
    expect(tester.read('p3/lib/p3.txt.copy'), '1');
    expect(tester.read('.dart_tool/build/generated/p3/lib/p3.txt.hidden'), '1');

    // Add a package to the workspace that are direct and indirect dependencies
    // of `p1`.
    tester.writePackage(
      name: 'p1',
      dependencies: ['build_runner'],
      pathDependencies: ['builder_pkg', 'cache_builder_pkg'],
      workspaceDependencies: ['p4'],
      files: {'lib/p1.txt': '1'},
      inWorkspace: true,
    );
    tester.writePackage(
      name: 'p4',
      workspaceDependencies: ['p5'],
      files: {'lib/p4.txt': '1'},
      inWorkspace: true,
    );
    tester.writePackage(
      name: 'p5',
      files: {'lib/p5.txt': '1'},
      inWorkspace: true,
    );
    tester.write('pubspec.yaml', '''
name: workspace
environment:
  sdk: ^3.5.0
workspace: [p1, p2, p3, p4, p5]
''');

    // Builders can apply to `p4` and `p5` because they are (transitive) deps
    // of `p1`.
    await tester.run('', 'dart run build_runner build --workspace');
    // `AutoApply.root` does not apply because the builder is not a transitive
    // dep of `p4` or `p5`.
    expect(tester.read('p4/lib/p4.txt.copy'), null);
    // `AutoApply.all` does apply because the builder is in the build of `p1`
    // and `p4` and `p5` are also in the build of `p1`.
    expect(tester.read('.dart_tool/build/generated/p4/lib/p4.txt.hidden'), '1');
    expect(tester.read('.dart_tool/build/generated/p5/lib/p5.txt.hidden'), '1');

    // Write a builder that applies another builder in its build.yaml.
    tester.writeFixturePackage(
      FixturePackages.copyBuilder(
        packageName: 'second_copy_builder_pkg',
        outputExtension: '.copy2',
        appliesBuilders: '["builder_pkg|test_builder"]',
        pathDependencies: ['builder_pkg'],
      ),
    );
    tester.writePackage(
      name: 'p6',
      files: {'lib/p6.txt': '1'},
      pathDependencies: ['second_copy_builder_pkg'],
      inWorkspace: true,
    );
    tester.write('pubspec.yaml', '''
name: workspace
environment:
  sdk: ^3.5.0
workspace: [p1, p2, p3, p4, p5, p6]
''');

    // The builder applied by second_copy_builder_pkg runs despite not
    // being auto applied.
    await tester.run('', 'dart run build_runner build --workspace');
    expect(tester.read('p6/lib/p6.txt.copy'), '1');
  });
}
