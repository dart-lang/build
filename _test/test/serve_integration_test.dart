// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
import 'dart:convert';
import 'dart:io' show HttpClient, HttpHeaders, HttpStatus;

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'common/utils.dart';

void main() {
  HttpClient httpClient;
  setUpAll(() async {
    // These tests depend on running `test` while a `serve` is ongoing.
    await startServer(
        ensureCleanBuild: true, buildArgs: ['--skip-build-script-check']);
    httpClient = HttpClient();
  });

  tearDownAll(() async {
    await stopServer(cleanUp: true);
    httpClient.close();
  });

  test('Doesn\'t compile submodules into the root module', () {
    expect(readGeneratedFileAsString('_test/test/hello_world_test.ddc.js'),
        isNot(contains('Hello World!')));
  });

  test('Can run passing tests with --pub-serve', () async {
    await expectTestsPass(usePrecompiled: false);
  }, skip: 'TODO: Get non-custom html tests passing with pub serve');

  test('Serves a directory list when it fails to fallback on index.html',
      () async {
    var request = await httpClient.get('localhost', 8080, 'dir_without_index/');
    var firstResponse = await request.close();
    expect(firstResponse.statusCode, HttpStatus.notFound);
    expect(await utf8.decodeStream(firstResponse),
        contains('dir_without_index/hello.txt'));
  });

  group('File changes', () {
    setUp(() async {
      ensureCleanGitClient();
    });

    test('ddc errors can be fixed', () async {
      var path = p.join('test', 'common', 'message.dart');
      var error = nextStdOutLine('Error compiling dartdevc module:'
          '_test|test/common/message.ddc.js');
      var nextBuild = nextFailedBuild;
      await replaceAllInFile(path, "'Hello World!'", '1');
      await error;
      await nextBuild;

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
      var firstRequest =
          await httpClient.get('localhost', 8080, 'main.dart.js');
      var firstResponse = await firstRequest.close();
      expect(firstResponse.statusCode, HttpStatus.ok);
      var etag = firstResponse.headers[HttpHeaders.etagHeader];
      expect(etag, isNotNull);

      var cachedRequest =
          await httpClient.get('localhost', 8080, 'main.dart.js');
      cachedRequest.headers.add(HttpHeaders.ifNoneMatchHeader, etag);
      var cachedResponse = await cachedRequest.close();
      expect(cachedResponse.statusCode, HttpStatus.notModified);
    });

    group('regression tests', () {
      test('can get changes to files not read during build', () async {
        var firstRequest =
            await httpClient.get('localhost', 8080, 'index.html');
        var firstResponse = await firstRequest.close();
        expect(firstResponse.statusCode, HttpStatus.ok);
        var etag = firstResponse.headers[HttpHeaders.etagHeader];
        expect(etag, isNotNull);

        var cachedRequest =
            await httpClient.get('localhost', 8080, 'index.html')
              ..headers.add(HttpHeaders.ifNoneMatchHeader, etag);
        var cachedResponse = await cachedRequest.close();
        expect(cachedResponse.statusCode, HttpStatus.notModified);

        var nextBuild = nextSuccessfulBuild;
        await replaceAllInFile(
            'web/index.html', 'integration tests', 'modified example');
        await nextBuild;
        var changedRequest =
            await httpClient.get('localhost', 8080, 'index.html')
              ..headers.add(HttpHeaders.ifNoneMatchHeader, etag);
        var changedResponse = await changedRequest.close();
        expect(changedResponse.statusCode, HttpStatus.ok);
        var newEtag = changedResponse.headers[HttpHeaders.etagHeader];
        expect(newEtag, isNot(etag));
      });
    });
  });
}
