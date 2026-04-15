// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Tags(['integration3'])
library;

import 'package:build_runner/src/logging/build_log.dart';
import 'package:test/test.dart';

import '../common/common.dart';

void main() async {
  test('build process locks in workspace', () async {
    final pubspecs = await Pubspecs.load();
    final tester = BuildRunnerTester(pubspecs);

    tester.writeFixturePackage(
      FixturePackages.copyBuilder(
        packageName: 'builder_pkg',
        delayAtBuildStart: true,
        applyToAllPackages: true,
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
      name: 'p2',
      dependencies: ['build_runner'],
      pathDependencies: ['builder_pkg'],
      files: {'lib/p2.txt': '1'},
      inWorkspace: true,
    );
    tester.writeWorkspacePubspec(packages: ['p1', 'p2']);

    // Two single package builds can run concurrently.
    final build1 = await tester.start('p1', 'dart run build_runner build');
    final build2 = await tester.start('p2', 'dart run build_runner build');
    final output1 = await build1.expectAndGetBlock(BuildLog.successPattern);
    final output2 = await build2.expectAndGetBlock(BuildLog.successPattern);
    expect(
      output1,
      isNot(contains('Waiting for already-running build_runner.')),
    );
    expect(
      output2,
      isNot(contains('Waiting for already-running build_runner.')),
    );

    // Workspace build blocks on single package build.
    final build3 = await tester.start('p1', 'dart run build_runner build');
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final build4 = await tester.start(
      '',
      'dart run build_runner build --workspace',
    );
    await build4.expect('Waiting for already-running build_runner.');
    await build3.expect(BuildLog.successPattern);
    await build4.expect(BuildLog.successPattern);

    // Single package build blocks on workspace build.
    final build5 = await tester.start(
      '',
      'dart run build_runner build --workspace',
    );
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final build6 = await tester.start('p1', 'dart run build_runner build');
    await build6.expect('Waiting for already-running build_runner.');
    await build5.expect(BuildLog.successPattern);
    await build6.expect(BuildLog.successPattern);

    // Watch mode in a package exits if requested via `stop --workspace`.
    final watch = await tester.start('p1', 'dart run build_runner watch');
    await watch.expect(BuildLog.successPattern);
    await tester
        .run('p1', 'dart run build_runner stop --workspace')
        .timeout(const Duration(seconds: 5));
    await watch.expect('Exiting as requested by another build_runner process.');
    await watch.exitCode;

    // Watch mode in a package exits if requested via `stop` (without
    // --workspace).
    final watch2 = await tester.start('p1', 'dart run build_runner watch');
    await watch2.expect(BuildLog.successPattern);
    await tester
        .run('p1', 'dart run build_runner stop')
        .timeout(const Duration(seconds: 5));
    await watch2.expect(
      'Exiting as requested by another build_runner process.',
    );
    await watch2.exitCode;

    // Watch mode in a package exits if requested via `stop --workspace` from
    // another package.
    final watch3 = await tester.start('p1', 'dart run build_runner watch');
    await watch3.expect(BuildLog.successPattern);
    await tester
        .run('p2', 'dart run build_runner stop --workspace')
        .timeout(const Duration(seconds: 5));
    await watch3.expect(
      'Exiting as requested by another build_runner process.',
    );
    await watch3.exitCode;
  });
}
