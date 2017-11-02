// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';
import 'package:watcher/watcher.dart';

import 'package:build_runner/build_runner.dart';
import 'package:build_runner/src/generate/watch_impl.dart' as watch_impl;

import '../common/common.dart';

void main() {
  FutureOr<Response> Function(Request) handler;
  InMemoryRunnerAssetReader reader;
  InMemoryRunnerAssetWriter writer;
  StreamSubscription subscription;
  Completer<BuildResult> nextBuild;
  StreamController terminateController;

  final path = p.absolute('example');

  setUp(() async {
    final graph = new PackageGraph.fromRoot(
      new PackageNode.noPubspec('example', path: path),
    );
    writer = new InMemoryRunnerAssetWriter();
    reader = new InMemoryRunnerAssetReader(writer.assets, 'example');
    reader.cacheStringAsset(
        new AssetId('example', 'web/initial.txt'), 'initial');
    terminateController = new StreamController();
    final server = (await watch_impl.watch(
      [
        new BuildAction(const UppercaseBuilder(), 'example'),
      ],
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
