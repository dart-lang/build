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
    // These tests depend on running `test` while a `serve` is ongoing.
    await startServer(
        ensureCleanBuild: true, buildArgs: ['--skip-build-script-check']);
  });

  tearDownAll(() async {
    await stopServer(cleanUp: true);
  });

  test('Doesn\'t compile submodules into the root module', () {
    expect(readGeneratedFileAsString('_test/test/hello_world_test.ddc.js'),
        isNot(contains('Hello World!')));
  });

  test('Can run passing tests with --pub-serve', () async {
    await expectTestsPass(usePrecompiled: false);
  }, skip: 'TODO: Get non-custom html tests passing with pub serve');

  group('File changes', () {
    setUp(() async {
      ensureCleanGitClient();
    });

    test('ddc errors can be fixed', () async {
      var path = p.join('test', 'common', 'message.dart');
      var error = nextStdErrLine('Error compiling dartdevc module:'
          '_test|test/common/message.ddc.js');
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
      var path = p.join('web', 'expected.fail');

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
            'web/index.html', 'integration tests', 'modified example');
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
