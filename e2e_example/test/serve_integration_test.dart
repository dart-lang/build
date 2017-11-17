// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
import 'dart:io' show HttpClient, HttpHeaders, HttpStatus;

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'common/utils.dart';

void main() {
  setUpAll(() async {
    await startManualServer(ensureCleanBuild: true, verbose: true);
  });

  tearDownAll(() async {
    await stopServer(cleanUp: true);
  });

  test('Doesn\'t compile submodules into the root module', () {
    expect(readGeneratedFileAsString('e2e_example/test/hello_world_test.js'),
        isNot(contains('Hello World!')));
  });

  test('Can run passing tests with --pub-serve', () async {
    await expectTestsPass();
  });

  test('Can run passing tests with --precompiled', () async {
    await expectTestsPass(usePrecompiled: true);
  });

  group('File changes', () {
    setUp(() async {
      ensureCleanGitClient();
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
      await expectTestsPass(expectedNumRan: 3);
    });

    test('delete test', () async {
      var nextBuild = nextSuccessfulBuild;
      await deleteFile(p.join('test', 'subdir', 'subdir_test.dart'));
      await nextBuild;
      await expectTestsPass(expectedNumRan: 1);
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

final basicTestContents = '''
import 'package:test/test.dart';

main() {
  test('1 == 1', () {
    expect(1, equals(1));
  });
}''';
