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
    expect(
        readGeneratedFileAsString('e2e_example/test/hello_world_test.ddc.js'),
        isNot(contains('Hello World!')));
  });

  test('Can run passing tests with --pub-serve', () async {
    await expectTestsPass(usePrecompiled: false);
  }, skip: 'TODO: Get non-custom html tests passing with pub serve');

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
      await expectTestsPass(expectedNumRan: 4);
    });

    test('delete test', () async {
      var nextBuild = nextSuccessfulBuild;
      await deleteFile(p.join('test', 'subdir', 'subdir_test.dart'));
      await nextBuild;
      await expectTestsPass(expectedNumRan: 2);
    });

    test('ddc errors can be fixed', () async {
      var path = p.join('test', 'common', 'message.dart');
      var error = nextStdErrLine('Error compiling dartdevc module:'
          'e2e_example|test/common/message.ddc.js');
      var nextBuild = nextSuccessfulBuild;
      await replaceAllInFile(path, "'Hello World!'", '1');
      await error;
      await nextBuild;
      await expectTestsFail();

      nextBuild = nextSuccessfulBuild;
      await replaceAllInFile(path, '1', "'Hello World!'");
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

    group('regression tests', () {
      test('can get changes to files not read during build', () async {
        var httpClient = new HttpClient();
        var firstRequest =
            await httpClient.get('localhost', 8080, 'index.html');
        var firstResponse = await firstRequest.close();
        expect(firstResponse.statusCode, HttpStatus.OK);
        var etag = firstResponse.headers[HttpHeaders.ETAG];
        expect(etag, isNotNull);

        var cachedRequest =
            await httpClient.get('localhost', 8080, 'index.html')
              ..headers.add(HttpHeaders.IF_NONE_MATCH, etag);
        var cachedResponse = await cachedRequest.close();
        expect(cachedResponse.statusCode, HttpStatus.NOT_MODIFIED);

        var nextBuild = nextSuccessfulBuild;
        await replaceAllInFile(
            'web/index.html', 'e2e_example', 'modified example');
        await nextBuild;
        var changedRequest =
            await httpClient.get('localhost', 8080, 'index.html')
              ..headers.add(HttpHeaders.IF_NONE_MATCH, etag);
        var changedResponse = await changedRequest.close();
        expect(changedResponse.statusCode, HttpStatus.OK);
        var newEtag = changedResponse.headers[HttpHeaders.ETAG];
        expect(newEtag, isNot(etag));
      });
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
