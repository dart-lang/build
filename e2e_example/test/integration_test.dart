// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

Directory toolDir = new Directory(p.join('.dart_tool', 'build'));
Process process;
Stream<String> stdOutLines;

void main() {
  setUpAll(() async {
    // Make sure this is a clean build
    if (await toolDir.exists()) {
      await toolDir.delete(recursive: true);
    }

    process = await Process.start('dart', ['tool/build.dart']);
    stdOutLines = process.stdout
        .transform(UTF8.decoder)
        .transform(const LineSplitter())
        .asBroadcastStream();
    stdOutLines.listen(print);
    await nextSuccessfulBuild;
  });

  tearDownAll(() async {
    expect(process.kill(), true);
    await process.exitCode;

    await toolDir.delete(recursive: true);
  });

  test('Can run passing tests', () async {
    await expectTestsPass();
  });

  group('File edits', () {
    bool gitWasClean = false;

    void ensureCleanGitClient() {
      var gitStatus = Process.runSync('git', ['status']).stdout as String;
      gitWasClean = gitStatus.contains('nothing to commit, working tree clean');
      expect(gitWasClean, isTrue,
          reason: 'Not running on a clean git client, aborting test.');
    }

    setUp(() async {
      ensureCleanGitClient();
      await expectTestsPass();
    });

    tearDown(() async {
      if (gitWasClean) {
        // Reset our state after each test, assuming we didn't abandon tests due
        // to a non-pristine git environment.
        Process.runSync('git', ['reset', '--hard']);
        await nextSuccessfulBuild;
      }
    });

    test('change test to fail and rerun', () async {
      await replaceAllInFile(
          'test/hello_world_test.dart', 'Hello World!', 'Goodbye World!');
      await nextSuccessfulBuild;
      await expectTestsFail();
    });

    test('change dependency lib causing test to fail and rerun', () async {
      await replaceAllInFile('lib/app.dart', 'Hello World!', 'Goodbye World!');
      await nextSuccessfulBuild;
      await expectTestsFail();
    });
  });
}

Future get nextSuccessfulBuild =>
    stdOutLines.firstWhere((line) => line.contains('build completed'));

Future<ProcessResult> runTests() =>
    Process.run('pub', ['run', 'test', '--pub-serve', '8081', '-p', 'chrome']);

Future<Null> expectTestsFail() async {
  var result = await runTests();
  expect(result.stdout, contains('Some tests failed'));
}

Future<Null> expectTestsPass() async {
  var result = await runTests();
  expect(result.stdout, contains('All tests passed!'));
}

Future<Null> replaceAllInFile(String path, String from, String replace) async {
  var file = new File(path);
  expect(await file.exists(), isTrue);
  var content = await file.readAsString();
  await file.writeAsString(content.replaceAll(from, replace));
}
