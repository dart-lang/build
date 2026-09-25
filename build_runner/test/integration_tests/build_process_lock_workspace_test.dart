// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Tags(['integration3'])
library;

import 'package:build_runner/src/logging/build_log.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../common/common.dart';

void main() async {
  test('build process locks in workspace', () async {
    final pubspecs = await Pubspecs.load();
    final tester = BuildRunnerTester(pubspecs);

    // While `gate` does not exist, builds block at the start of each build
    // step, holding the build process lock.
    tester.write('gate', '');
    tester.writeFixturePackage(
      FixturePackages.copyBuilder(
        packageName: 'builder_pkg',
        waitForFileAtBuildStart: p.join(tester.tempDirectory.path, 'gate'),
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
    final build1 = await tester.start(
      'p1',
      'dart run build_runner build --force-jit',
    );
    final build2 = await tester.start(
      'p2',
      'dart run build_runner build --force-jit',
    );
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
    tester.delete('gate');
    tester.write('p1/lib/p1.txt', '2');
    final build3 = await tester.start(
      'p1',
      'dart run build_runner build --force-jit',
    );
    await build3.expect('builder_pkg:test_builder');
    final build4 = await tester.start(
      '',
      'dart run build_runner build --force-jit --workspace',
    );
    await build4.expect('Waiting for already-running build_runner.');
    tester.write('gate', '');
    await build3.expect(BuildLog.successPattern);
    await build4.expect(BuildLog.successPattern);

    // Single package build blocks on workspace build.
    tester.delete('gate');
    tester.write('p1/lib/p1.txt', '3');
    final build5 = await tester.start(
      '',
      'dart run build_runner build --force-jit --workspace',
    );
    await build5.expect('builder_pkg:test_builder');
    final build6 = await tester.start(
      'p1',
      'dart run build_runner build --force-jit',
    );
    await build6.expect('Waiting for already-running build_runner.');
    tester.write('gate', '');
    await build5.expect(BuildLog.successPattern);
    await build6.expect(BuildLog.successPattern);

    // Watch mode in a package exits if requested via `stop --workspace`.
    final watch = await tester.start(
      'p1',
      'dart run build_runner watch --force-jit',
    );
    await watch.expect(BuildLog.successPattern);
    await tester.run('p1', 'dart run build_runner stop --workspace');
    await watch.expect('Exiting as requested by another build_runner process.');
    await watch.exitCode;

    // Watch mode in a package exits if requested via `stop` (without
    // --workspace).
    final watch2 = await tester.start(
      'p1',
      'dart run build_runner watch --force-jit',
    );
    await watch2.expect(BuildLog.successPattern);
    await tester.run('p1', 'dart run build_runner stop');
    await watch2.expect(
      'Exiting as requested by another build_runner process.',
    );
    await watch2.exitCode;

    // Watch mode in a package exits if requested via `stop --workspace` from
    // another package.
    final watch3 = await tester.start(
      'p1',
      'dart run build_runner watch --force-jit',
    );
    await watch3.expect(BuildLog.successPattern);
    await tester.run('p2', 'dart run build_runner stop --workspace');
    await watch3.expect(
      'Exiting as requested by another build_runner process.',
    );
    await watch3.exitCode;
  });
}
