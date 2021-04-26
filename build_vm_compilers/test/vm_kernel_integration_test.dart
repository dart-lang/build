// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:_test_common/common.dart';
import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

void main() {
  group('without null safety', () => _runTests(false));
  group('with null safety', () => _runTests(true));
}

void _runTests(bool nullSafe) {
  group('can compile vm apps to kernel', () {
    setUpAll(() async {
      final versionComment = nullSafe ? '' : '// @dart=2.9\n';

      await d.dir('a', [
        await pubspec(
          'a',
          currentIsolateDependencies: [
            'analyzer',
            'build',
            'build_config',
            'build_daemon',
            'build_modules',
            'build_resolvers',
            'build_runner',
            'build_runner_core',
            'build_vm_compilers',
            'code_builder',
            'scratch_space',
          ],
          versionDependencies: {
            'glob': 'any',
            'path': 'any',
          },
          sdkEnvironment: nullSafe ? '>=2.12.0 <3.0.0' : '>=2.9.0 <3.0.0',
        ),
        d.dir('bin', [
          d.file('hello.dart', '''
$versionComment
import 'package:path/path.dart' as p;

void main() {
  print(p.url.join('hello', 'world'));
}
'''),
          d.file('goodbye.dart', '''
$versionComment
import 'package:path/path.dart' as p;

import 'hello.dart';

void main() {
  print(p.url.join('goodbye', 'world'));
}
'''),
          d.file('sync_async.dart', '''
$versionComment
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
      expect(buildResult.exitCode, 0, reason: buildResult.stderr as String?);
    });

    test(' and run them', () async {
      var runResult = await runDart('a', 'out/bin/hello.vm.app.dill');

      expect(runResult.exitCode, 0, reason: runResult.stderr as String?);
      expect(runResult.stdout, 'hello/world$_newLine');
    });

    test(' and run root libraries main', () async {
      var runResult = await runDart('a', 'out/bin/goodbye.vm.app.dill');

      expect(runResult.exitCode, 0, reason: runResult.stderr as String?);
      expect(runResult.stdout, 'goodbye/world$_newLine');
    });

    test(' and enables sync-async', () async {
      var runResult = await runDart('a', 'out/bin/sync_async.vm.app.dill');

      expect(runResult.exitCode, 0, reason: runResult.stderr as String?);

      expect(runResult.stdout,
          'before${_newLine}running${_newLine}after$_newLine');
    });
  });
}

final _newLine = Platform.isWindows ? '\r\n' : '\n';
