// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';
import 'package:watcher/watcher.dart';

import 'package:build_runner/build_runner.dart';
import 'package:build_runner/src/generate/watch_impl.dart' as watch_impl;

import '../common/common.dart';
import '../common/package_graphs.dart';

void main() {
  FutureOr<Response> Function(Request) handler;
  InMemoryRunnerAssetReader reader;
  InMemoryRunnerAssetWriter writer;
  StreamSubscription subscription;
  Completer<BuildResult> nextBuild;
  StreamController terminateController;

  final path = p.absolute('example');

  setUp(() async {
    final graph = buildPackageGraph({rootPackage('example', path: path): []});
    writer = new InMemoryRunnerAssetWriter();
    reader = new InMemoryRunnerAssetReader.shareAssetCache(writer.assets,
        rootPackage: 'example');
    reader.cacheStringAsset(
        new AssetId('example', 'web/initial.txt'), 'initial');
    reader.cacheStringAsset(new AssetId('example', '.packages'), '''
# Fake packages file
example:file://fake/pkg/path
''');
    terminateController = new StreamController();
    final server = (await watch_impl.watch(
      [applyToRoot(const UppercaseBuilder())],
      packageGraph: graph,
      reader: reader,
      writer: writer,
      logLevel: Level.OFF,
      directoryWatcherFactory: (path) => new FakeWatcher(path),
      terminateEventStream: terminateController.stream,
      skipBuildScriptCheck: true,
    ));
    handler = server.handlerFor('web');

    nextBuild = new Completer<BuildResult>();
    subscription = server.buildResults.listen((result) {
      nextBuild.complete(result);
      nextBuild = new Completer<BuildResult>();
    });
    await nextBuild.future;
  });

  tearDown(() async {
    await subscription.cancel();
    terminateController.add(null);
    await terminateController.close();
  });

  test('should serve original files', () async {
    final getHello = Uri.parse('http://localhost/initial.txt');
    final response = await handler(new Request('GET', getHello));
    expect(await response.readAsString(), 'initial');
  });

  test('should serve built files', () async {
    final getHello = Uri.parse('http://localhost/initial.g.txt');
    reader.cacheStringAsset(
        new AssetId('example', 'web/initial.g.txt'), 'INITIAL');
    final response = await handler(new Request('GET', getHello));
    expect(await response.readAsString(), 'INITIAL');
  });

  test('should 404 on missing files', () async {
    final get404 = Uri.parse('http://localhost/404.txt');
    final response = await handler(new Request('GET', get404));
    expect(await response.readAsString(), 'Not Found');
  });

  test('should serve newly added files', () async {
    final getNew = Uri.parse('http://localhost/new.txt');
    reader.cacheStringAsset(new AssetId('example', 'web/new.txt'), 'New');
    await new Future.value();
    FakeWatcher.notifyWatchers(
      new WatchEvent(ChangeType.ADD, '$path/web/new.txt'),
    );
    await nextBuild.future;
    final response = await handler(new Request('GET', getNew));
    expect(await response.readAsString(), 'New');
  });

  test('should serve built newly added files', () async {
    final getNew = Uri.parse('http://localhost/new.g.txt');
    reader.cacheStringAsset(new AssetId('example', 'web/new.txt'), 'New');
    await new Future.value();
    FakeWatcher.notifyWatchers(
      new WatchEvent(ChangeType.ADD, '$path/web/new.txt'),
    );
    await nextBuild.future;
    final response = await handler(new Request('GET', getNew));
    expect(await response.readAsString(), 'NEW');
  });

  group(r'/$graph', () {
    test('should (try) to send the HTML page', () async {
      try {
        await handler(
            new Request('GET', Uri.parse(r'http://localhost/$graph')));
        fail('Assets are not wired up. Expecting this to throw.');
      } catch (e) {
        expect(e, new isInstanceOf<AssetNotFoundException>());
        expect((e as AssetNotFoundException).assetId,
            new AssetId.parse('build_runner|lib/src/server/graph_viz.html'));
      }
    });

    void test404(String testName, String path, String expected) {
      test(testName, () async {
        var response = await handler(
            new Request('GET', Uri.parse('http://localhost/\$graph/$path')));

        expect(response.statusCode, 404);
        expect(await response.readAsString(), expected);
      });
    }

    test404('404s on an unsupported URL', r'bob', 'Bad request: "bob".');
    test404('empty query causes 404', '?=', 'Bad request: "?=".');
    test404('bad asset query', '?q=bob|bob',
        'Could not find asset in build graph: bob|bob');
    test404(
        'bad path query',
        '?q=bob/bob',
        'Could not find asset for path "bob/bob". Tried:\n'
        '- example|bob/bob\n'
        '- example|web/bob');

    void testSuccess(String testName, String path, String expectedId) {
      test(testName, () async {
        var response = await handler(
            new Request('GET', Uri.parse('http://localhost/\$graph/$path')));

        var output = await response.readAsString();
        expect(response.statusCode, 200, reason: output);
        var json = jsonDecode(output) as Map<String, dynamic>;

        expect(json, containsPair('primary', containsPair('id', expectedId)));
      });
    }

    testSuccess('valid path', '?q=web/initial.txt', 'example|web/initial.txt');
    testSuccess(
        'valid path, 2nd try', '?q=bob/initial.txt', 'example|web/initial.txt');
    testSuccess('valid AssetId', '?q=example|web/initial.txt',
        'example|web/initial.txt');
  });
}

class UppercaseBuilder implements Builder {
  const UppercaseBuilder();

  @override
  Future<Null> build(BuildStep buildStep) async {
    final content = await buildStep.readAsString(buildStep.inputId);
    await buildStep.writeAsString(
      buildStep.inputId.changeExtension('.g.txt'),
      content.toUpperCase(),
    );
  }

  @override
  final buildExtensions = const {
    'txt': const ['g.txt']
  };
}
