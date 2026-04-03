// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Tags(['integration1'])
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../common/common.dart';

void main() async {
  test('build command universal lock test', () async {
    final pubspecs = await Pubspecs.load();
    final tester = BuildRunnerTester(pubspecs);

    tester.writePackage(
      name: 'root_pkg',
      dependencies: ['build_runner'],
      files: {'web/a.txt': 'a'},
    );

    final lockPath = p.join(
      tester.tempDirectory.path,
      'root_pkg',
      '.dart_tool',
      'build',
      'runner.lock',
    );
    final lockFile = File(lockPath)..createSync(recursive: true);
    final openLock = lockFile.openSync(mode: FileMode.write)
      ..lockSync(FileLock.exclusive);

    // Write metadata to simulate a running process.
    openLock.writeStringSync('''
pid: 84732
command: watch
''');

    String? output;
    try {
      output = await tester.run(
        'root_pkg',
        'dart run build_runner build',
        expectExitCode: 78, // ExitCode.config.code
      );
    } finally {
      openLock.closeSync();
    }

    expect(
      output,
      contains(
        'Build failed: Another instance of `build_runner` is currently running',
      ),
    );
  });
}
