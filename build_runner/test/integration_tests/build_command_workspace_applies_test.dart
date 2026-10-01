// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Tags(['integration4'])
library;

import 'package:test/test.dart';

import '../common/common.dart';

void main() async {
  test('build command workspace applies builders', () async {
    final pubspecs = await Pubspecs.load();
    final tester = BuildRunnerTester(pubspecs);

    tester.writeFixturePackage(
      FixturePackages.copyBuilder(packageName: 'builder_pkg'),
    );
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
      name: 'p1',
      dependencies: ['build_runner'],
      pathDependencies: ['builder_pkg'],
      files: {'lib/p1.txt': '1'},
      inWorkspace: true,
    );
    tester.writePackage(
      name: 'p6',
      files: {'lib/p6.txt': '1'},
      pathDependencies: ['second_copy_builder_pkg'],
      inWorkspace: true,
    );
    tester.writeWorkspacePubspec(packages: ['p1', 'p6']);

    // The builder applied by second_copy_builder_pkg runs despite not
    // being auto applied.
    await tester.run('', 'dart run build_runner build --force-jit --workspace');
    expect(tester.read('p6/lib/p6.txt.copy'), '1');

    // Support for globs in workspaces was added in 3.11.
    tester.writeWorkspacePubspec(
      packages: ["'p*'"],
      sdkBound: '>=3.11.0 <4.0.0',
    );
    await tester.run('', 'dart run build_runner build --force-jit --workspace');

    // Write a builder that applies an unknown builder in its build.yaml, the
    // unknown builder is ignored.
    tester.writeFixturePackage(
      FixturePackages.copyBuilder(
        packageName: 'second_copy_builder_pkg',
        outputExtension: '.copy2',
        buildToCache: true,
        appliesBuilders: '["unknown|test_builder"]',
        pathDependencies: ['builder_pkg'],
      ),
    );
    await tester.run('', 'dart run build_runner build --force-jit --workspace');
  });
}
