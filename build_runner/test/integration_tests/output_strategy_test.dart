// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Tags(['integration'])
library;

import 'package:build_runner/src/logging/build_log.dart';
import 'package:test/test.dart';

import '../common/common.dart';

void main() async {
  test(
    'output strategy',
    timeout: const Timeout(Duration(minutes: 5)),
    () async {
      final pubspecs = await Pubspecs.load();
      final tester = BuildRunnerTester(pubspecs);

      tester.writeFixturePackage(FixturePackages.copyBuilder());
      tester.writePackage(
        name: 'root_pkg',
        dependencies: ['build_runner'],
        pathDependencies: ['builder_pkg'],
        files: {'web/a.txt': 'a', 'web/b.txt': 'b', 'web/c.txt': 'c'},
      );

      // Initial build.
      var build = await tester.start(
        'root_pkg',
        'dart run build_runner build --force-jit',
      );
      await build.expect(BuildLog.successPattern);
      expect(await build.exitCode, 0);
      expect(tester.read('root_pkg/web/a.txt.copy'), 'a');

      // Overwrite is default behavior even without input changes.
      tester.write('root_pkg/web/a.txt.copy', 'User modified a');
      build = await tester.start(
        'root_pkg',
        'dart run build_runner build --force-jit',
      );
      await build.expect(BuildLog.successPattern);
      expect(await build.exitCode, 0);
      expect(tester.read('root_pkg/web/a.txt.copy'), 'a');

      // Overwrite is default behavior with input changes.
      tester.write('root_pkg/web/a.txt.copy', 'User modified a');
      tester.write('root_pkg/web/a.txt', 'a2');
      build = await tester.start(
        'root_pkg',
        'dart run build_runner build --force-jit',
      );
      await build.expect(BuildLog.successPattern);
      expect(await build.exitCode, 0);
      expect(tester.read('root_pkg/web/a.txt.copy'), 'a2');

      // --keep-modified-outputs keeps developer modifications.
      tester.write('root_pkg/web/a.txt.copy', 'User modified a');
      build = await tester.start(
        'root_pkg',
        'dart run build_runner build --force-jit --keep-modified-outputs',
      );
      await build.expect(BuildLog.successPattern);
      expect(await build.exitCode, 0);
      expect(tester.read('root_pkg/web/a.txt.copy'), 'User modified a');

      // Restore state.
      tester.delete('root_pkg/web/a.txt.copy');
      tester.write('root_pkg/web/a.txt', 'a');
      tester.write('root_pkg/web/b.txt', 'b');
      tester.write('root_pkg/web/c.txt', 'c');
      build = await tester.start(
        'root_pkg',
        'dart run build_runner build --force-jit --delete-conflicting-outputs',
      );
      await build.expect(BuildLog.successPattern);
      expect(await build.exitCode, 0);

      // --only-check passes incrementally.
      build = await tester.start(
        'root_pkg',
        'dart run build_runner build --force-jit --only-check',
      );
      await build.expect(BuildLog.successPattern);
      expect(await build.exitCode, 0);

      // --only-check fails incrementally on M, D, A.
      tester.write('root_pkg/web/a.txt.copy', 'User modified a');
      tester.delete('root_pkg/web/b.txt.copy');
      tester.delete('root_pkg/web/c.txt');
      build = await tester.start(
        'root_pkg',
        'dart run build_runner build --force-jit --only-check',
      );
      await build.expect('Verify failed due to Unexpected|Incorrect|Missing:');
      await build.expect(RegExp('.*web/a.txt.copy'));
      await build.expect(RegExp('.*web/b.txt.copy'));
      await build.expect(RegExp('.*web/c.txt.copy'));
      await build.expect(BuildLog.failurePattern);
      expect(
        await build.exitCode,
        1,
      ); // Failed verification usually has exit code 73

      // --only-check passes cleanly.
      tester.write('root_pkg/web/a.txt.copy', 'a2');
      tester.write('root_pkg/web/b.txt.copy', 'b');
      tester.write('root_pkg/web/c.txt', 'c');
      build = await tester.start(
        'root_pkg',
        'dart run build_runner build --force-jit',
      );
      await build.expect(BuildLog.successPattern);
      expect(await build.exitCode, 0);

      tester.delete('root_pkg/.dart_tool');
      build = await tester.start(
        'root_pkg',
        'dart run build_runner build --force-jit --only-check',
      );
      await build.expect(BuildLog.successPattern);
      expect(await build.exitCode, 0);

      // --only-check fails cleanly on M, D.
      build = await tester.start(
        'root_pkg',
        'dart run build_runner build --force-jit',
      );
      await build.expect(BuildLog.successPattern);
      expect(await build.exitCode, 0);

      tester.write('root_pkg/web/a.txt.copy', 'User modified a');
      tester.delete('root_pkg/web/b.txt.copy');
      tester.delete('root_pkg/.dart_tool');

      build = await tester.start(
        'root_pkg',
        'dart run build_runner build --force-jit --only-check',
      );
      await build.expect('Verify failed due to Unexpected|Incorrect|Missing:');
      await build.expect(RegExp('.*web/a.txt.copy'));
      await build.expect(RegExp('.*web/b.txt.copy'));
      await build.expect(BuildLog.failurePattern);
      expect(await build.exitCode, 1);

      // watch --only-check stream verification.
      tester.write('root_pkg/web/a.txt.copy', 'a2');
      tester.write('root_pkg/web/b.txt.copy', 'b');
      build = await tester.start(
        'root_pkg',
        'dart run build_runner build --force-jit',
      );
      await build.expect(BuildLog.successPattern);
      expect(await build.exitCode, 0);

      final watch = await tester.start(
        'root_pkg',
        'dart run build_runner watch --force-jit --only-check',
      );
      await watch.expect(BuildLog.successPattern);

      tester.write('root_pkg/web/a.txt.copy', 'User modified a');
      await watch.expect('Verify failed due to Unexpected|Incorrect|Missing:');
      await watch.expect('I web/a.txt.copy');
      await watch.expect(BuildLog.failurePattern);

      tester.write('root_pkg/web/a.txt.copy', 'a');
      await watch.expect(BuildLog.successPattern);
      await watch.kill();
    },
  );
}
