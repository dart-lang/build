// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:build/build.dart';
import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:test/test.dart';

import 'package:build_runner/build_runner.dart';
import 'package:build_runner_core/build_runner_core.dart';
import 'package:build_runner_core/src/asset_graph/graph.dart';
import 'package:build_runner_core/src/asset_graph/node.dart';
import 'package:build_runner_core/src/asset_graph/optional_output_tracker.dart';
import 'package:build_runner_core/src/generate/performance_tracker.dart';
import 'package:build_runner/src/generate/watch_impl.dart';
import 'package:build_runner/src/server/server.dart';

import 'package:_test_common/common.dart';
import 'package:_test_common/package_graphs.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  ServeHandler serveHandler;
  InMemoryRunnerAssetReader reader;
  MockWatchImpl watchImpl;
  AssetGraph assetGraph;

  setUp(() async {
    reader = InMemoryRunnerAssetReader();
    final packageGraph = buildPackageGraph({rootPackage('a'): []});
    assetGraph = await AssetGraph.build([], Set(), Set(), packageGraph, reader);
    watchImpl = MockWatchImpl(
        FinalizedReader(
            reader, assetGraph, OptionalOutputTracker(assetGraph, [], []), 'a'),
        packageGraph,
        assetGraph);
    serveHandler = createServeHandler(watchImpl);
    watchImpl
        .addFutureResult(Future.value(BuildResult(BuildStatus.success, [])));
  });

  void _addSource(String id, String content, {bool deleted = false}) {
    var node = makeAssetNode(id, [], computeDigest('a'));
    if (deleted) {
      node.deletedBy.add(node.id.addExtension('.post_anchor.1'));
    }
    assetGraph.add(node);
    reader.cacheStringAsset(node.id, content);
  }

  test('can get handlers for a subdirectory', () async {
    _addSource('a|web/index.html', 'content');
    var response = await serveHandler.handlerFor('web')(
        Request('GET', Uri.parse('http://server.com/index.html')));
    expect(await response.readAsString(), 'content');
  });

  test('caching with etags works', () async {
    _addSource('a|web/index.html', 'content');
    var handler = serveHandler.handlerFor('web');
    var requestUri = Uri.parse('http://server.com/index.html');
    var firstResponse = await handler(Request('GET', requestUri));
    var etag = firstResponse.headers[HttpHeaders.etagHeader];
    expect(etag, isNotNull);
    expect(firstResponse.statusCode, HttpStatus.ok);
    expect(await firstResponse.readAsString(), 'content');

    var cachedResponse = await handler(Request('GET', requestUri,
        headers: {HttpHeaders.ifNoneMatchHeader: etag}));
    expect(cachedResponse.statusCode, HttpStatus.notModified);
    expect(await cachedResponse.readAsString(), isEmpty);
  });

  test('throws if you pass a non-root directory', () {
    expect(() => serveHandler.handlerFor('web/sub'), throwsArgumentError);
  });

  group('build failures', () {
    setUp(() async {
      _addSource('a|web/index.html', '');
      assetGraph.add(GeneratedAssetNode(
        makeAssetId('a|web/main.ddc.js'),
        builderOptionsId: null,
        phaseNumber: null,
        state: NodeState.upToDate,
        isHidden: false,
        wasOutput: true,
        isFailure: true,
        primaryInput: null,
      ));
      watchImpl
          .addFutureResult(Future.value(BuildResult(BuildStatus.failure, [])));
    });

    test('serves successful assets', () async {
      var response = await serveHandler.handlerFor('web')(
          Request('GET', Uri.parse('http://server.com/index.html')));

      expect(response.statusCode, HttpStatus.ok);
    });

    test('rejects requests for failed assets', () async {
      var response = await serveHandler.handlerFor('web')(
          Request('GET', Uri.parse('http://server.com/main.ddc.js')));

      expect(response.statusCode, HttpStatus.internalServerError);
    });

    test('logs rejected requests', () async {
      expect(
          Logger.root.onRecord,
          emitsThrough(predicate<LogRecord>((record) =>
              record.message.contains('main.ddc.js') &&
              record.level == Level.WARNING)));
      await serveHandler.handlerFor('web', logRequests: true)(
          Request('GET', Uri.parse('http://server.com/main.ddc.js')));
    });
  });

  test('logs requests if you ask it to', () async {
    _addSource('a|web/index.html', 'content');
    expect(
        Logger.root.onRecord,
        emitsThrough(predicate<LogRecord>((record) =>
            record.message.contains('index.html') &&
            record.level == Level.INFO)));
    await serveHandler.handlerFor('web', logRequests: true)(
        Request('GET', Uri.parse('http://server.com/index.html')));
  });

  group(r'/$perf', () {
    test('serves some sort of page if enabled', () async {
      var tracker = BuildPerformanceTracker()..start();
      var actionTracker = tracker.startBuilderAction(
          makeAssetId('a|web/a.txt'), 'test_builder');
      actionTracker.track(() {}, 'SomeLabel');
      tracker.stop();
      actionTracker.stop();
      watchImpl.addFutureResult(Future.value(
          BuildResult(BuildStatus.success, [], performance: tracker)));
      await Future(() {});
      var response = await serveHandler.handlerFor('web')(
          Request('GET', Uri.parse(r'http://server.com/$perf')));

      expect(response.statusCode, HttpStatus.ok);
      expect(await response.readAsString(),
          allOf(contains('test_builder:a|web/a.txt'), contains('SomeLabel')));
    });

    test('serves an error page if not enabled', () async {
      watchImpl.addFutureResult(Future.value(BuildResult(
          BuildStatus.success, [],
          performance: BuildPerformanceTracker.noOp())));
      await Future(() {});
      var response = await serveHandler.handlerFor('web')(
          Request('GET', Uri.parse(r'http://server.com/$perf')));

      expect(response.statusCode, HttpStatus.ok);
      expect(await response.readAsString(), contains('--track-performance'));
    });
  });

  test('serve asset digests', () async {
    _addSource('a|web/index.html', 'content1');
    _addSource('a|lib/some.dart.js', 'content2');
    _addSource('a|lib/another.dart.js', 'content3');
    var response = await serveHandler.handlerFor('web')(Request(
        'GET', Uri.parse('http://server.com/\$assetDigests'),
        body: jsonEncode([
          'index.html',
          'packages/a/some.dart.js',
          'packages/a/absent.dart.js'
        ])));
    expect(jsonDecode(await response.readAsString()), {
      'index.html': '7e55db001d319a94b0b713529a756623',
      'packages/a/some.dart.js': 'eea670f4ac941df71a3b5f268ebe3eac',
    });
  });

  group('build updates', () {
    test('injects client code if enabled', () async {
      _addSource('a|web/some.js', entrypointExtensionMarker + '\nalert(1)');
      var response = await serveHandler.handlerFor('web', liveReload: true)(
          Request('GET', Uri.parse('http://server.com/some.js')));
      expect(await response.readAsString(), contains('hot_reload_client.dart'));
    });

    test('doesn\'t inject client code if disabled', () async {
      _addSource('a|web/some.js', entrypointExtensionMarker + '\nalert(1)');
      var response = await serveHandler.handlerFor('web', liveReload: false)(
          Request('GET', Uri.parse('http://server.com/some.js')));
      expect(await response.readAsString(),
          isNot(contains('hot_reload_client.dart')));
    });

    test('doesn\'t inject client code in non-js files', () async {
      _addSource('a|web/some.html', entrypointExtensionMarker + '\n<br>some');
      var response = await serveHandler.handlerFor('web', liveReload: true)(
          Request('GET', Uri.parse('http://server.com/some.html')));
      expect(await response.readAsString(),
          isNot(contains('hot_reload_client.dart')));
    });

    test('doesn\'t inject client code in non-marked files', () async {
      _addSource('a|web/some.js', 'alert(1)');
      var response = await serveHandler.handlerFor('web', liveReload: true)(
          Request('GET', Uri.parse('http://server.com/some.js')));
      expect(await response.readAsString(),
          isNot(contains('hot_reload_client.dart')));
    });

    test('expect websocket connection if enabled', () async {
      _addSource('a|web/index.html', 'content');
      expect(
          serveHandler.handlerFor('web', liveReload: true)(
              Request('GET', Uri.parse('ws://server.com/'),
                  headers: {
                    'Connection': 'Upgrade',
                    'Upgrade': 'websocket',
                    'Sec-WebSocket-Version': '13',
                    'Sec-WebSocket-Key': 'abc',
                  },
                  onHijack: (f) {})),
          throwsA(TypeMatcher<HijackException>()));
    });

    test('reject websocket connection if disabled', () async {
      _addSource('a|web/index.html', 'content');
      var response = await serveHandler.handlerFor('web', liveReload: false)(
          Request('GET', Uri.parse('ws://server.com/'), headers: {
        'Connection': 'Upgrade',
        'Upgrade': 'websocket',
        'Sec-WebSocket-Version': '13',
        'Sec-WebSocket-Key': 'abc',
      }));
      expect(response.statusCode, 200);
      expect(await response.readAsString(), 'content');
    });

    group('WebSocket handler', () {
      BuildUpdatesWebSocketHandler handler;
      Future<void> Function(WebSocketChannel, String) createMockConnection;

      // client to server stream controlllers
      StreamController<List<int>> c2sController1;
      StreamController<List<int>> c2sController2;
      // server to client stream controlllers
      StreamController<List<int>> s2cController1;
      StreamController<List<int>> s2cController2;

      WebSocketChannel clientChannel1;
      WebSocketChannel clientChannel2;
      WebSocketChannel serverChannel1;
      WebSocketChannel serverChannel2;

      setUp(() {
        var mockHandlerFactory = (Function onConnect, {protocols}) =>
            (request) => Response(200, context: {'onConnect': onConnect});

        createMockConnection =
            (WebSocketChannel serverChannel, String rootDir) async {
          var mockResponse =
              await handler.createHandlerByRootDir(rootDir)(null);
          var onConnect = mockResponse.context['onConnect'] as Function;
          onConnect(serverChannel, '');
        };

        handler = BuildUpdatesWebSocketHandler(watchImpl, mockHandlerFactory);

        c2sController1 = StreamController<List<int>>();
        s2cController1 = StreamController<List<int>>();
        serverChannel1 = WebSocketChannel(
            StreamChannel(c2sController1.stream, s2cController1.sink),
            serverSide: true);
        clientChannel1 = WebSocketChannel(
            StreamChannel(s2cController1.stream, c2sController1.sink),
            serverSide: false);

        c2sController2 = StreamController<List<int>>();
        s2cController2 = StreamController<List<int>>();
        serverChannel2 = WebSocketChannel(
            StreamChannel(c2sController2.stream, s2cController2.sink),
            serverSide: true);
        clientChannel2 = WebSocketChannel(
            StreamChannel(s2cController2.stream, c2sController2.sink),
            serverSide: false);
      });

      tearDown(() {
        c2sController1.close();
        s2cController1.close();
        c2sController2.close();
        s2cController2.close();
      });

      test('emmits a message to all listners', () async {
        expect(clientChannel1.stream, emitsInOrder(['{}', emitsDone]));
        expect(clientChannel2.stream, emitsInOrder(['{}', emitsDone]));
        await createMockConnection(serverChannel1, 'web');
        await createMockConnection(serverChannel2, 'web');
        await handler.emitUpdateMessage(BuildResult(BuildStatus.success, []));
        await clientChannel1.sink.close();
        await clientChannel2.sink.close();
      });

      test('deletes listners on disconect', () async {
        expect(clientChannel1.stream, emitsInOrder(['{}', '{}', emitsDone]));
        expect(clientChannel2.stream, emitsInOrder(['{}', emitsDone]));
        await createMockConnection(serverChannel1, 'web');
        await createMockConnection(serverChannel2, 'web');
        await handler.emitUpdateMessage(BuildResult(BuildStatus.success, []));
        await clientChannel2.sink.close();
        await handler.emitUpdateMessage(BuildResult(BuildStatus.success, []));
        await clientChannel1.sink.close();
      });

      test('emmits only on successful builds', () async {
        expect(clientChannel1.stream, emitsDone);
        await createMockConnection(serverChannel1, 'web');
        await handler.emitUpdateMessage(BuildResult(BuildStatus.failure, []));
        await clientChannel1.sink.close();
      });

      test('emmits build results digests', () async {
        _addSource('a|web/index.html', 'content1');
        _addSource('a|lib/some.dart.js', 'content2');
        expect(
            clientChannel1.stream.map((s) => jsonDecode(s.toString())),
            emitsInOrder([
              {'index.html': '7e55db001d319a94b0b713529a756623'},
              {
                'index.html': '7e55db001d319a94b0b713529a756623',
                'packages/a/some.dart.js': 'eea670f4ac941df71a3b5f268ebe3eac'
              },
              emitsDone
            ]));
        await createMockConnection(serverChannel1, 'web');
        await handler.emitUpdateMessage(BuildResult(BuildStatus.success, [
          AssetId('a', 'web/index.html'),
        ]));
        await handler.emitUpdateMessage(BuildResult(BuildStatus.success, [
          AssetId('a', 'web/index.html'),
          AssetId('a', 'lib/some.dart.js'),
        ]));
        await clientChannel1.sink.close();
      });

      test('works for different root dirs', () async {
        _addSource('a|web1/index.html', 'content1');
        _addSource('a|web2/index.html', 'content2');
        _addSource('a|lib/some.dart.js', 'content3');
        expect(
            clientChannel1.stream.map((s) => jsonDecode(s.toString())),
            emitsInOrder([
              {
                'index.html': '7e55db001d319a94b0b713529a756623',
                'packages/a/some.dart.js': 'c96310e55d9677b978eae0dada47642c'
              },
              emitsDone
            ]));
        expect(
            clientChannel2.stream.map((s) => jsonDecode(s.toString())),
            emitsInOrder([
              {
                'index.html': 'eea670f4ac941df71a3b5f268ebe3eac',
                'packages/a/some.dart.js': 'c96310e55d9677b978eae0dada47642c'
              },
              emitsDone
            ]));
        await createMockConnection(serverChannel1, 'web1');
        await createMockConnection(serverChannel2, 'web2');
        await handler.emitUpdateMessage(BuildResult(BuildStatus.success, [
          AssetId('a', 'web1/index.html'),
          AssetId('a', 'web2/index.html'),
          AssetId('a', 'lib/some.dart.js'),
        ]));
        await clientChannel1.sink.close();
        await clientChannel2.sink.close();
      });
    });
  });
}

class MockWatchImpl implements WatchImpl {
  @override
  final AssetGraph assetGraph;

  Future<BuildResult> _currentBuild;
  @override
  Future<BuildResult> get currentBuild => _currentBuild;
  @override
  set currentBuild(newValue) => throw UnsupportedError('unsupported!');

  final _futureBuildResultsController = StreamController<Future<BuildResult>>();
  final _buildResultsController = StreamController<BuildResult>();

  @override
  get buildResults => _buildResultsController.stream;
  @override
  set buildResults(_) => throw UnsupportedError('unsupported!');

  @override
  final PackageGraph packageGraph;

  @override
  final FinalizedReader reader;

  void addFutureResult(Future<BuildResult> result) {
    _futureBuildResultsController.add(result);
  }

  MockWatchImpl(this.reader, this.packageGraph, this.assetGraph) {
    var firstBuild = Completer<BuildResult>();
    _currentBuild = firstBuild.future;
    _futureBuildResultsController.stream.listen((futureBuildResult) {
      if (!firstBuild.isCompleted) {
        firstBuild.complete(futureBuildResult);
      }
      _currentBuild = _currentBuild.then((_) => futureBuildResult);
      _currentBuild.then(_buildResultsController.add);
    });
  }

  @override
  Future<Null> get ready => Future.value(null);
}
