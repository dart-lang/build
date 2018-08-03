// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

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
    reader = new InMemoryRunnerAssetReader();
    final packageGraph = buildPackageGraph({rootPackage('a'): []});
    assetGraph =
        await AssetGraph.build([], new Set(), new Set(), packageGraph, reader);
    watchImpl = new MockWatchImpl(
        new FinalizedReader(
            reader, assetGraph, new OptionalOutputTracker(assetGraph, [], [])),
        packageGraph,
        assetGraph);
    serveHandler = createServeHandler(watchImpl);
    watchImpl.addFutureResult(
        new Future.value(new BuildResult(BuildStatus.success, [])));
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
        new Request('GET', Uri.parse('http://server.com/index.html')));
    expect(await response.readAsString(), 'content');
  });

  test('caching with etags works', () async {
    _addSource('a|web/index.html', 'content');
    var handler = serveHandler.handlerFor('web');
    var requestUri = Uri.parse('http://server.com/index.html');
    var firstResponse = await handler(new Request('GET', requestUri));
    var etag = firstResponse.headers[HttpHeaders.etagHeader];
    expect(etag, isNotNull);
    expect(firstResponse.statusCode, HttpStatus.ok);
    expect(await firstResponse.readAsString(), 'content');

    var cachedResponse = await handler(new Request('GET', requestUri,
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
      assetGraph.add(new GeneratedAssetNode(
        makeAssetId('a|web/main.ddc.js'),
        builderOptionsId: null,
        phaseNumber: null,
        state: GeneratedNodeState.upToDate,
        isHidden: false,
        wasOutput: true,
        isFailure: true,
        primaryInput: null,
      ));
      watchImpl.addFutureResult(
          new Future.value(new BuildResult(BuildStatus.failure, [])));
    });

    test('serves successful assets', () async {
      var response = await serveHandler.handlerFor('web')(
          new Request('GET', Uri.parse('http://server.com/index.html')));

      expect(response.statusCode, HttpStatus.ok);
    });

    test('rejects requests for failed assets', () async {
      var response = await serveHandler.handlerFor('web')(
          new Request('GET', Uri.parse('http://server.com/main.ddc.js')));

      expect(response.statusCode, HttpStatus.internalServerError);
    });

    test('logs rejected requests', () async {
      expect(
          Logger.root.onRecord,
          emitsThrough(predicate<LogRecord>((record) =>
              record.message.contains('main.ddc.js') &&
              record.level == Level.WARNING)));
      await serveHandler.handlerFor('web', logRequests: true)(
          new Request('GET', Uri.parse('http://server.com/main.ddc.js')));
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
        new Request('GET', Uri.parse('http://server.com/index.html')));
  });

  group(r'/$perf', () {
    test('serves some sort of page if enabled', () async {
      var tracker = new BuildPerformanceTracker()..start();
      var actionTracker = tracker.startBuilderAction(
          makeAssetId('a|web/a.txt'), 'test_builder');
      actionTracker.track(() {}, 'SomeLabel');
      tracker.stop();
      actionTracker.stop();
      watchImpl.addFutureResult(new Future.value(
          new BuildResult(BuildStatus.success, [], performance: tracker)));
      await new Future(() {});
      var response = await serveHandler.handlerFor('web')(
          new Request('GET', Uri.parse(r'http://server.com/$perf')));

      expect(response.statusCode, HttpStatus.ok);
      expect(await response.readAsString(),
          allOf(contains('test_builder:a|web/a.txt'), contains('SomeLabel')));
    });

    test('serves an error page if not enabled', () async {
      watchImpl.addFutureResult(new Future.value(new BuildResult(
          BuildStatus.success, [],
          performance: new BuildPerformanceTracker.noOp())));
      await new Future(() {});
      var response = await serveHandler.handlerFor('web')(
          new Request('GET', Uri.parse(r'http://server.com/$perf')));

      expect(response.statusCode, HttpStatus.ok);
      expect(await response.readAsString(), contains('--track-performance'));
    });
  });

  group('build updates', () {
    final _entrypointExtensionMarker = '/* ENTRYPOINT_EXTENTION_MARKER */';

    test('injects client code if enabled', () async {
      _addSource('a|web/some.js', _entrypointExtensionMarker);
      var response = await serveHandler.handlerFor('web', liveReload: true)(
          new Request('GET', Uri.parse('http://server.com/some.js')));
      expect(await response.readAsString(), contains('\$livereload'));
    });

    test('doesn\'t inject client code if disabled', () async {
      _addSource('a|web/some.js', _entrypointExtensionMarker);
      var response = await serveHandler.handlerFor('web', liveReload: false)(
          new Request('GET', Uri.parse('http://server.com/some.js')));
      expect(await response.readAsString(), isNot(contains('\$livereload')));
    });

    test('doesn\'t inject client code in non-js files', () async {
      _addSource('a|web/some.html', _entrypointExtensionMarker);
      var response = await serveHandler.handlerFor('web', liveReload: true)(
          new Request('GET', Uri.parse('http://server.com/some.html')));
      expect(await response.readAsString(), isNot(contains('\$livereload')));
    });

    test('doesn\'t inject client code in non-marked files', () async {
      _addSource('a|web/some.js', 'content');
      var response = await serveHandler.handlerFor('web', liveReload: true)(
          new Request('GET', Uri.parse('http://server.com/some.js')));
      expect(await response.readAsString(), isNot(contains('\$livereload')));
    });

    test('expect websocket connection if enabled', () async {
      _addSource('a|web/index.html', 'content');
      expect(
          serveHandler.handlerFor('web', liveReload: true)(
              new Request('GET', Uri.parse('ws://server.com/'),
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
          new Request('GET', Uri.parse('ws://server.com/'), headers: {
        'Connection': 'Upgrade',
        'Upgrade': 'websocket',
        'Sec-WebSocket-Version': '13',
        'Sec-WebSocket-Key': 'abc',
      }));
      expect(response.statusCode, 200);
      expect(await response.readAsString(), 'content');
    });

    test('emmits a message to all listners', () async {
      Function exposedOnConnect;
      var mockHandlerFactory = (Function onConnect, {protocols}) {
        exposedOnConnect = onConnect;
      };
      var buildUpdatesWebSocketHandler =
          BuildUpdatesWebSocketHandler(mockHandlerFactory);

      var streamControllerFirst1 = StreamController<List<int>>();
      var streamControllerFirst2 = StreamController<List<int>>();
      var serverChannelFirst = WebSocketChannel(
          StreamChannel(
              streamControllerFirst1.stream, streamControllerFirst2.sink),
          serverSide: true);
      var clientChannelFirst = WebSocketChannel(
          StreamChannel(
              streamControllerFirst2.stream, streamControllerFirst1.sink),
          serverSide: false);

      var streamControllerSecond1 = StreamController<List<int>>();
      var streamControllerSecond2 = StreamController<List<int>>();
      var serverChannelSecond = WebSocketChannel(
          StreamChannel(
              streamControllerSecond1.stream, streamControllerSecond2.sink),
          serverSide: true);
      var clientChannelSecond = WebSocketChannel(
          StreamChannel(
              streamControllerSecond2.stream, streamControllerSecond1.sink),
          serverSide: false);

      var deferredExpect1 = clientChannelFirst.stream.single
          .then((value) => expect(value, 'update'));
      var deferredExpect2 = clientChannelSecond.stream.single
          .then((value) => expect(value, 'update'));
      exposedOnConnect(serverChannelFirst, '');
      exposedOnConnect(serverChannelSecond, '');
      buildUpdatesWebSocketHandler.emitUpdateMessage(null);
      await clientChannelFirst.sink.close();
      await clientChannelSecond.sink.close();
      await deferredExpect1;
      await deferredExpect2;
    });

    test('deletes listners on disconect', () async {
      Function exposedOnConnect;
      var mockHandlerFactory = (Function onConnect, {protocols}) {
        exposedOnConnect = onConnect;
      };
      var buildUpdatesWebSocketHandler =
          BuildUpdatesWebSocketHandler(mockHandlerFactory);

      var streamControllerFirst1 = StreamController<List<int>>();
      var streamControllerFirst2 = StreamController<List<int>>();
      var serverChannelFirst = WebSocketChannel(
          StreamChannel(
              streamControllerFirst1.stream, streamControllerFirst2.sink),
          serverSide: true);
      var clientChannelFirst = WebSocketChannel(
          StreamChannel(
              streamControllerFirst2.stream, streamControllerFirst1.sink),
          serverSide: false);

      var streamControllerSecond1 = StreamController<List<int>>();
      var streamControllerSecond2 = StreamController<List<int>>();
      var serverChannelSecond = WebSocketChannel(
          StreamChannel(
              streamControllerSecond1.stream, streamControllerSecond2.sink),
          serverSide: true);
      var clientChannelSecond = WebSocketChannel(
          StreamChannel(
              streamControllerSecond2.stream, streamControllerSecond1.sink),
          serverSide: false);

      var deferredExpect1 = clientChannelFirst.stream
          .toList()
          .then((value) => expect(value, ['update', 'update']));
      var deferredExpect2 = clientChannelSecond.stream.single
          .then((value) => expect(value, 'update'));
      exposedOnConnect(serverChannelFirst, '');
      exposedOnConnect(serverChannelSecond, '');
      buildUpdatesWebSocketHandler.emitUpdateMessage(null);
      await clientChannelSecond.sink.close();
      buildUpdatesWebSocketHandler.emitUpdateMessage(null);
      await clientChannelFirst.sink.close();
      await deferredExpect1;
      await deferredExpect2;
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
  set currentBuild(newValue) => throw new UnsupportedError('unsupported!');

  final _futureBuildResultsController =
      new StreamController<Future<BuildResult>>();
  final _buildResultsController = new StreamController<BuildResult>();

  @override
  get buildResults => _buildResultsController.stream;
  @override
  set buildResults(_) => throw new UnsupportedError('unsupported!');

  @override
  final PackageGraph packageGraph;

  @override
  final FinalizedReader reader;

  void addFutureResult(Future<BuildResult> result) {
    _futureBuildResultsController.add(result);
  }

  MockWatchImpl(this.reader, this.packageGraph, this.assetGraph) {
    var firstBuild = new Completer<BuildResult>();
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
  Future<Null> get ready => new Future.value(null);
}
