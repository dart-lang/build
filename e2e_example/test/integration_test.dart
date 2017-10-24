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
Stream<String> stdErrLines;
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

    stdErrLines = process.stderr
        .transform(UTF8.decoder)
        .transform(const LineSplitter())
        .asBroadcastStream();
    stdErrLines.listen(print);

    await nextSuccessfulBuild;
  });

  tearDownAll(() async {
    expect(process.kill(), true);
    await process.exitCode;

    await toolDir.delete(recursive: true);
  });

  test('Doesn\'t compile submodules into the root module', () {
    var testJsFile = new File(p.join('.dart_tool', 'build', 'generated',
        'e2e_example', 'test', 'hello_world_test.js'));
    expect(testJsFile.readAsStringSync(), isNot(contains('Hello World!')));
  });

  test('Can run passing tests', () async {
    await expectTestsPass();
  });

  group('File changes', () {
    bool gitWasClean = false;

    void ensureCleanGitClient() {
      var gitStatus = Process.runSync('git', ['status', '.']).stdout as String;
      gitWasClean = gitStatus.contains('nothing to commit, working tree clean');
      expect(gitWasClean, isTrue,
          reason: 'Not running on a clean git client, aborting test.\n'
              '`git status .` gave:\n$gitStatus');
    }

    setUp(() async {
      ensureCleanGitClient();
    });

    tearDown(() async {
      if (gitWasClean) {
        // Reset our state after each test, assuming we didn't abandon tests due
        // to a non-pristine git environment.
        Process.runSync('git', ['checkout', 'HEAD', '--', '.']);
        // Delete the untracked files.
        var gitStatus = Process
            .runSync('git', ['status', '--porcelain', '.']).stdout as String;

        var untracked = gitStatus
            .split('\n')
            .where((line) => line.startsWith('??'))
            .map((line) => line.split(' ')[1])
            .map((path) {
          var parts = p.split(path);
          assert(parts[0] == 'e2e_example');
          return p.joinAll(parts.skip(1));
        });
        for (var path in untracked) {
          Process.runSync('rm', [path]);
        }
        await nextSuccessfulBuild;
      }
    });

    test('edit test to fail and rerun', () async {
      await replaceAllInFile(
          'test/common/message.dart', 'Hello World!', 'Goodbye World!');
      await nextSuccessfulBuild;
      await expectTestsFail();
    });

    test('edit dependency lib causing test to fail and rerun', () async {
      await replaceAllInFile('lib/app.dart', 'Hello World!', 'Goodbye World!');
      await nextSuccessfulBuild;
      await expectTestsFail();
    });

    test('create new test', () async {
      await createFile(p.join('test', 'other_test.dart'), basicTestContents);
      await nextSuccessfulBuild;
      await expectTestsPass();
    });
  });
}

Future get nextSuccessfulBuild =>
    stdOutLines.firstWhere((line) => line.contains('Build: Succeeded after'));

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

Future<Null> createFile(String path, String contents) async {
  var file = new File(path);
  expect(await file.exists(), isFalse);
  await file.create(recursive: true);
  await file.writeAsString(contents);
}

Future<Null> replaceAllInFile(String path, String from, String replace) async {
  var file = new File(path);
  expect(await file.exists(), isTrue);
  var content = await file.readAsString();
  await file.writeAsString(content.replaceAll(from, replace));
}

final basicTestContents = '''
import 'package:test/test.dart';

main() {
  test('1 == 1', () {
    expect(1, equals(1));
  });
}''';
