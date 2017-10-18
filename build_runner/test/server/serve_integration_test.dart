// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart';
import 'package:build_runner/build_runner.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';
import 'package:watcher/watcher.dart';

import '../common/common.dart';

void main() {
  FutureOr<Response> Function(Request) handler;
  InMemoryRunnerAssetReader reader;
  InMemoryRunnerAssetWriter writer;
  StreamSubscription subscription;
  Completer<BuildResult> nextBuild;

  final path = p.absolute('example');

  setUp(() async {
    final graph = new PackageGraph.fromRoot(
      new PackageNode.noPubspec('example', path: path),
    );
    reader = new InMemoryRunnerAssetReader({}, 'example');
    writer = new InMemoryRunnerAssetWriter();
    final server = (await watch(
      [
        new BuildAction(const UppercaseBuilder(), 'example'),
      ],
      packageGraph: graph,
      reader: reader,
      writer: writer,
      logLevel: Level.ALL,
      directoryWatcherFactory: (path) => new FakeWatcher(path),
    ));
    handler = server.handlerFor('web');

    nextBuild = new Completer<BuildResult>();
    subscription = server.buildResults.listen((result) {
      nextBuild.complete(result);
      nextBuild = new Completer<BuildResult>();
    });
    await nextBuild.future;
  });

  tearDown(() => subscription.cancel());

  test('should serve original files', () async {
    final getHello = Uri.parse('http://localhost/hello.txt');
    reader.cacheStringAsset(new AssetId('example', 'web/hello.txt'), 'Hello');
    final response = await handler(new Request('GET', getHello));
    expect(await response.readAsString(), 'Hello');
  });

  test('should serve built files', () async {
    final getHello = Uri.parse('http://localhost/hello.g.txt');
    reader.cacheStringAsset(new AssetId('example', 'web/hello.g.txt'), 'HELLO');
    final response = await handler(new Request('GET', getHello));
    expect(await response.readAsString(), 'HELLO');
  });

  test('should 404 on missing files', () async {
    final get404 = Uri.parse('http://localhost/404.txt');
    final response = await handler(new Request('GET', get404));
    expect(await response.readAsString(), 'Not Found');
  });

  test('should serve newly added files', () async {
    final getNew = Uri.parse('http://localhost/new.txt');
    reader.cacheStringAsset(new AssetId('example', 'web/new.txt'), 'New');
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
    var result = await nextBuild.future;
    for (var output in result.outputs) {
      reader.cacheStringAsset(output, writer.assets[output].stringValue);
    }
    final response = await handler(new Request('GET', getNew));
    expect(await response.readAsString(), 'NEW');
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
