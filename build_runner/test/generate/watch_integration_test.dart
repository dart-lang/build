// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

import '../common/common.dart';

Process process;
Stream<String> stdErrLines;
Stream<String> stdOutLines;

final String originalBuildContent = '''
import 'package:build_runner/build_runner.dart';
import 'package:build_test/build_test.dart';

main() async {
  await watch(
    [new BuildAction(new CopyBuilder(), 'a')], deleteFilesByDefault: true);
}
''';

main() {
  group('watch integration tests', () {
    setUp(() async {
      await d.dir('a', [
        await pubspec('a', currentIsolateDependencies: [
          'build',
          'build_runner',
          'build_test',
          'glob'
        ]),
        d.dir('tool', [d.file('build.dart', originalBuildContent)]),
        d.dir('web', [
          d.file('a.txt', 'a'),
        ]),
      ]).create();

      await pubGet('a');

      // Run a build and validate the output.
      process = await startDart('a', 'tool/build.dart');

      stdOutLines = process.stdout
          .transform(UTF8.decoder)
          .transform(const LineSplitter())
          .asBroadcastStream();

      stdErrLines = process.stderr
          .transform(UTF8.decoder)
          .transform(const LineSplitter())
          .asBroadcastStream();

      await nextSuccessfulBuild;
      await d.dir('a', [
        d.dir('web', [d.file('a.txt.copy', 'a')])
      ]).validate();
    });

    group('build script', () {
      test('updates the process to quit', () async {
        // Append a newline to the build script!
        await d.dir('a', [
          d.dir('tool', [d.file('build.dart', '$originalBuildContent\n')])
        ]).create();

        await nextStdErrLine(
            'Watch: Terminating builds due to build script update');
        expect(await process.exitCode, equals(0));
      });
    });
  });
}

Future get nextSuccessfulBuild =>
    stdOutLines.firstWhere((line) => line.contains('Build: Succeeded after'));

Future nextStdErrLine(String message) =>
    stdErrLines.firstWhere((line) => line.contains(message));
