// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Tags(['integration4'])
library;

import 'package:test/test.dart';

import '../common/common.dart';

void main() async {
  test('build command workspace root', () async {
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
    tester.writePackage(
      name: 'p1',
      dependencies: ['build_runner'],
      pathDependencies: ['builder_pkg'],
      files: {'lib/p1.txt': '1'},
      inWorkspace: true,
    );
    // Workspace package with direct dependency on builder_pkg.
    tester.write('pubspec.yaml', '''
name: workspace
environment:
  sdk: ^3.5.0
dependencies:
  builder_pkg:
    path: builder_pkg
workspace: [p1]
''');
    tester.write('lib/w.txt', '1');

    // Build without --workspace then build with, no input change.
    await tester.run('', 'dart run build_runner build');
    expect(tester.read('lib/w.txt.copy'), '1');
    expect(
      tester.read('p1/lib/p1.txt.copy'),
      null,
    ); // No build of nested package.
    await tester.run('', 'dart run build_runner build --workspace');
    expect(tester.read('lib/w.txt.copy'), '1');
    expect(tester.read('p1/lib/p1.txt.copy'), '1');

    // Build without --workspace then build with, input change in between.
    await tester.run('', 'dart run build_runner build');
    expect(tester.read('lib/w.txt.copy'), '1');
    tester.write('lib/w.txt', '2');
    tester.write('p1/lib/p1.txt', '2');
    await tester.run('', 'dart run build_runner build --workspace');
    expect(tester.read('lib/w.txt.copy'), '2');
    expect(tester.read('p1/lib/p1.txt.copy'), '2');

    // Build without --workspace again, no input change.
    tester.write('p1/lib/p1.txt', '3');
    await tester.run('', 'dart run build_runner build');
    expect(tester.read('lib/w.txt.copy'), '2');
    expect(
      tester.read('p1/lib/p1.txt.copy'),
      '2',
    ); // No build of nested package.

    // Build with --workspace then without, input change in between.
    await tester.run('', 'dart run build_runner build --workspace');
    expect(tester.read('lib/w.txt.copy'), '2');
    expect(tester.read('p1/lib/p1.txt.copy'), '3');
    tester.write('lib/w.txt', '3');
    tester.write('p1/lib/p1.txt', '4');
    await tester.run('', 'dart run build_runner build');
    expect(tester.read('lib/w.txt.copy'), '3');
    expect(
      tester.read('p1/lib/p1.txt.copy'),
      '3',
    ); // No build of nested package.
  });
}
