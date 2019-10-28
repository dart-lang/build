// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

import 'package:_test_common/common.dart';

void main() {
  group('can compile vm apps to kernel', () {
    setUpAll(() async {
      await d.dir('a', [
        await pubspec('a', currentIsolateDependencies: [
          'analyzer',
          'build',
          'build_config',
          'build_daemon',
          'build_modules',
          'build_resolvers',
          'build_runner',
          'build_runner_core',
          'build_vm_compilers',
        ], versionDependencies: {
          'glob': 'any',
          'path': 'any',
        }),
        d.dir('bin', [
          d.file('hello.dart', '''
import 'package:path/path.dart' as p;

void main() {
  print(p.url.join('hello', 'world'));
}
'''),
          d.file('goodbye.dart', '''
import 'package:path/path.dart' as p;

import 'hello.dart';

void main() {
  print(p.url.join('goodbye', 'world'));
}
'''),
          d.file('sync_async.dart', '''
void main() async {
  print('before');
  printAsync();
  print('after');
}

void printAsync() async {
  print('running');
}
'''),
        ]),
      ]).create();

      await pubGet('a');

      // Run a build and expect it to succeed.
      var buildResult = await runPub('a', 'run',
          args: ['build_runner', 'build', '-o', 'out']);
      expect(buildResult.exitCode, 0, reason: buildResult.stderr as String);
    });

    test(' and run them', () async {
      var runResult = await runDart('a', 'out/bin/hello.vm.app.dill');

      expect(runResult.exitCode, 0, reason: runResult.stderr as String);
      expect(runResult.stdout, 'hello/world$_newLine');
    });

    test(' and run root libraries main', () async {
      var runResult = await runDart('a', 'out/bin/goodbye.vm.app.dill');

      expect(runResult.exitCode, 0, reason: runResult.stderr as String);
      expect(runResult.stdout, 'goodbye/world$_newLine');
    });

    test(' and enables sync-async', () async {
      var runResult = await runDart('a', 'out/bin/sync_async.vm.app.dill');

      expect(runResult.exitCode, 0, reason: runResult.stderr as String);

      expect(runResult.stdout,
          'before${_newLine}running${_newLine}after$_newLine');
    });
  });
}

final _newLine = Platform.isWindows ? '\r\n' : '\n';
