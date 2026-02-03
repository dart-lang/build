// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Tags(['integration3'])
library;

import 'package:build_runner/src/logging/build_log.dart';
import 'package:test/test.dart';

import '../common/common.dart';

void main() async {
  test('watch command workspace', () async {
    final pubspecs = await Pubspecs.load();
    final tester = BuildRunnerTester(pubspecs);

    // Workspace based on `build_command_workspace_test`, see that test
    // for explanations of the expectations.

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
    tester.writePackage(
      name: 'p1',
      dependencies: ['build_runner'],
      pathDependencies: ['builder_pkg', 'cache_builder_pkg'],
      workspaceDependencies: ['p4'],
      files: {'lib/p1.txt': '1'},
      inWorkspace: true,
    );
    tester.writePackage(
      name: 'p2',
      files: {'lib/p2.txt': '1'},
      inWorkspace: true,
    );
    tester.writePackage(
      name: 'p3',
      workspaceDependencies: ['p1'],
      files: {'lib/p3.txt': '1'},
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

    final watch = await tester.start(
      '',
      'dart run build_runner watch --workspace',
    );
    await watch.expect(BuildLog.successPattern);

    expect(tester.read('p1/lib/p1.txt.copy'), '1');
    expect(tester.read('.dart_tool/build/generated/p1/lib/p1.txt.hidden'), '1');
    expect(tester.read('p2/lib/p2.txt.copy'), null);
    expect(
      tester.read('.dart_tool/build/generated/p2/lib/p2.txt.hidden'),
      null,
    );
    expect(tester.read('p3/lib/p3.txt.copy'), '1');
    expect(tester.read('.dart_tool/build/generated/p3/lib/p3.txt.hidden'), '1');
    expect(tester.read('p4/lib/p4.txt.copy'), null);
    expect(tester.read('.dart_tool/build/generated/p4/lib/p4.txt.hidden'), '1');
    expect(tester.read('.dart_tool/build/generated/p5/lib/p5.txt.hidden'), '1');
    expect(tester.read('p6/lib/p6.txt.copy'), '1');

    // Change a file in each workspace package, check the output is updated.

    tester.write('p1/lib/p1.txt', '2');
    await watch.expect(BuildLog.successPattern);
    expect(tester.read('p1/lib/p1.txt.copy'), '2');
    expect(tester.read('.dart_tool/build/generated/p1/lib/p1.txt.hidden'), '2');

    tester.write('p2/lib/p2.txt', '2');
    await watch.expectNoOutput(const Duration(seconds: 1));

    tester.write('p3/lib/p3.txt', '2');
    await watch.expect(BuildLog.successPattern);
    expect(tester.read('p3/lib/p3.txt.copy'), '2');
    expect(tester.read('.dart_tool/build/generated/p3/lib/p3.txt.hidden'), '2');

    tester.write('p4/lib/p4.txt', '2');
    await watch.expect(BuildLog.successPattern);
    expect(tester.read('.dart_tool/build/generated/p4/lib/p4.txt.hidden'), '2');

    tester.write('p5/lib/p5.txt', '2');
    await watch.expect(BuildLog.successPattern);
    expect(tester.read('.dart_tool/build/generated/p5/lib/p5.txt.hidden'), '2');

    tester.write('p6/lib/p6.txt', '2');
    await watch.expect(BuildLog.successPattern);
    expect(tester.read('p6/lib/p6.txt.copy'), '2');
  });
}
