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
    stdOutLines.listen((l) => print('stdout: $l'));

    stdErrLines = process.stderr
        .transform(UTF8.decoder)
        .transform(const LineSplitter())
        .asBroadcastStream();
    stdErrLines.listen((l) => print('stderr: $l'));

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

    bool gitIsClean() {
      var gitStatus = Process.runSync('git', ['status', '.']).stdout as String;
      return gitStatus.contains('nothing to commit, working tree clean');
    }

    void ensureCleanGitClient() {
      gitWasClean = gitIsClean();
      expect(gitWasClean, isTrue,
          reason: 'Not running on a clean git client, aborting test.\n');
    }

    setUp(() async {
      ensureCleanGitClient();
    });

    tearDown(() async {
      if (gitWasClean) {
        if (gitIsClean()) return;

        // Reset our state after each test, assuming we didn't abandon tests due
        // to a non-pristine git environment.
        Process.runSync('git', ['checkout', 'HEAD', '--', '.']);
        // Delete the untracked files.
        var gitStatus = Process
            .runSync('git', ['status', '--porcelain', '.']).stdout as String;

        var nextBuild = nextSuccessfulBuild;
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
        await nextBuild;
      }
    });

    test('edit test to fail and rerun', () async {
      var nextBuild = nextSuccessfulBuild;
      await replaceAllInFile(
          'test/common/message.dart', 'Hello World!', 'Goodbye World!');
      await nextBuild;
      await expectTestsFail();
    });

    test('edit dependency lib causing test to fail and rerun', () async {
      var nextBuild = nextSuccessfulBuild;
      await replaceAllInFile('lib/app.dart', 'Hello World!', 'Goodbye World!');
      await nextBuild;
      await expectTestsFail();
    });

    test('create new test', () async {
      var nextBuild = nextSuccessfulBuild;
      await createFile(p.join('test', 'other_test.dart'), basicTestContents);
      await nextBuild;
      await expectTestsPass(3);
    });

    test('delete test', () async {
      var nextBuild = nextSuccessfulBuild;
      await deleteFile(p.join('test', 'subdir', 'subdir_test.dart'));
      await nextBuild;
      await expectTestsPass(1);
    });

    test('ddc errors can be fixed', () async {
      var path = p.join('test', 'common', 'message.dart');
      var error = nextStdErrLine('Error compiling dartdevc module:'
          'e2e_example|test/hello_world_test.js');
      var nextBuild = nextSuccessfulBuild;
      await deleteFile(path);
      await error;
      await nextBuild;

      nextBuild = nextSuccessfulBuild;
      await createFile(path, "String get message => 'Hello World!';");
      await nextBuild;
      await expectTestsPass();
    });

    test('build errors can be fixed', () async {
      var path = p.join('lib', 'expected.fail');

      var nextBuild = nextFailedBuild;
      await createFile(path, 'some error');
      await nextBuild;

      nextBuild = nextSuccessfulBuild;
      await deleteFile(path);
      await nextBuild;
    });

    test('can hit the server and get cached results', () async {
      var httpClient = new HttpClient();
      var firstRequest =
          await httpClient.get('localhost', 8080, 'main.dart.js');
      var firstResponse = await firstRequest.close();
      expect(firstResponse.statusCode, HttpStatus.OK);
      var etag = firstResponse.headers[HttpHeaders.ETAG];
      expect(etag, isNotNull);

      var cachedRequest =
          await httpClient.get('localhost', 8080, 'main.dart.js');
      cachedRequest.headers.add(HttpHeaders.IF_NONE_MATCH, etag);
      var cachedResponse = await cachedRequest.close();
      expect(cachedResponse.statusCode, HttpStatus.NOT_MODIFIED);
    });
  });
}

Future get nextSuccessfulBuild =>
    stdOutLines.firstWhere((line) => line.contains('Build: Succeeded after'));

Future get nextFailedBuild =>
    stdErrLines.firstWhere((line) => line.contains('Build: Failed after'));

Future nextStdErrLine(String message) =>
    stdErrLines.firstWhere((line) => line.contains(message));

Future<ProcessResult> runTests() =>
    Process.run('pub', ['run', 'test', '--pub-serve', '8081', '-p', 'chrome']);

Future<Null> expectTestsFail() async {
  var result = await runTests();
  expect(result.stdout, contains('Some tests failed'));
}

Future<Null> expectTestsPass([int numRan]) async {
  var result = await runTests();
  expect(result.stdout, contains('All tests passed!'));
  if (numRan != null) {
    expect(result.stdout, contains('+$numRan'));
    expect(result.stdout, isNot(contains('+${numRan + 1}')));
  }
}

Future<Null> createFile(String path, String contents) async {
  var file = new File(path);
  expect(await file.exists(), isFalse);
  await file.create(recursive: true);
  await file.writeAsString(contents);
}

Future<Null> deleteFile(String path) async {
  var file = new File(path);
  expect(await file.exists(), isTrue);
  await file.delete();
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
