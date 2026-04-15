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
  test('build process lock', () async {
    final pubspecs = await Pubspecs.load();
    final tester = BuildRunnerTester(pubspecs);

    tester.writePackage(
      name: 'root_pkg',
      dependencies: ['build_runner'],
      files: {},
    );

    // One build blocks waiting for another.
    final build1 = await tester.start(
      'root_pkg',
      'dart run build_runner build',
    );
    await build1.expect('compiling builders');
    final build2 = await tester.start(
      'root_pkg',
      'dart run build_runner build',
    );
    await build2.expect('Waiting for already-running build_runner.');
    await build1.exitCode;
    await build2.exitCode;

    // Lock waits for held lock to be released.
    final rootPath = p.join(tester.tempDirectory.path, 'root_pkg');
    tester.write('root_pkg/bin/take_until_killed.dart', '''
import 'dart:io';
import 'package:build_runner/src/bootstrap/build_process_lock.dart';
import 'package:build_runner/src/build_plan/build_paths.dart';
Future<void> main() async {
  final lock = BuildProcessLock(BuildPaths(
    packagePath: r'$rootPath',
    buildWorkspace: false,
    workspacePath: null,
  ));
  print('started');
  await lock.takeLock();
  print('got lock');
  await Future.delayed(Duration(minutes: 5));
}
''');

    final lock1 = await tester.start(
      'root_pkg',
      'dart run bin/take_until_killed.dart',
    );
    await lock1.expect('started');
    final lock2 = await tester.start(
      'root_pkg',
      'dart run bin/take_until_killed.dart',
    );
    await lock2.expect('started');
    await lock1.expect('got lock');
    await lock2.expect('Waiting for already-running build_runner.');
    await lock2.expectNoOutput(const Duration(milliseconds: 500));
    await lock1.kill();
    await lock2.expect('got lock');
    await lock2.kill();

    // Lock is requested when waiting for lock.
    tester.write('root_pkg/bin/take_until_requested.dart', '''
import 'dart:io';
import 'package:build_runner/src/bootstrap/build_process_lock.dart';
import 'package:build_runner/src/build_plan/build_paths.dart';
Future<void> main() async {
  final lock = BuildProcessLock(BuildPaths(
    packagePath: r'$rootPath',
    buildWorkspace: false,
    workspacePath: null,
  ));
  print('started');
  await lock.takeLock();
  print('got lock');
  while (!lock.isLockRequested()) {
    await Future.delayed(Duration(milliseconds: 100));
  }
  print('lock requested');
}
''');

    final lock3 = await tester.start(
      'root_pkg',
      'dart run bin/take_until_requested.dart',
    );
    await lock3.expect('started');
    await lock3.expect('got lock');
    final lock4 = await tester.start(
      'root_pkg',
      'dart run bin/take_until_requested.dart',
    );
    await lock4.expect('started');
    await lock3.expect('lock requested');
    await lock4.expect('got lock');

    // Create the requested file to wake up lock4.
    tester.write(
      'root_pkg/.dart_tool/build/lock/build_runner.lock.requested',
      '',
    );
    await lock4.expect('lock requested');

    // Watch mode exits if requested during a build.
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
    );
    var watch = await tester.start('p1', 'dart run build_runner watch');
    await watch.expect('builder_pkg:test_builder on 1 input');
    await tester.run('p1', 'dart run build_runner stop');
    await watch.expect('Exiting as requested by another build_runner process.');
    await watch.exitCode;

    // Watch mode exits if requested while idle.
    watch = await tester.start('p1', 'dart run build_runner watch');
    await watch.expect(BuildLog.successPattern);
    await tester.run('p1', 'dart run build_runner stop');
    await watch.expect('Exiting as requested by another build_runner process.');
    await watch.exitCode;
  });
}
