// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:async/async.dart';
import 'package:build/build.dart';
import 'package:build_runner/src/build/asset_graph/graph.dart';
import 'package:build_runner/src/build/asset_graph/node.dart';
import 'package:build_runner/src/build/asset_graph/post_process_build_step_id.dart';
import 'package:build_runner/src/build/build_result.dart';
import 'package:build_runner/src/build_plan/build_phases.dart';
import 'package:build_runner/src/build_plan/package_graph.dart';
import 'package:build_runner/src/commands/serve/server.dart';
import 'package:build_runner/src/commands/watch/watcher.dart';
import 'package:build_runner/src/io/build_output_reader.dart';
import 'package:built_collection/built_collection.dart';
import 'package:crypto/crypto.dart';
import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:test/fake.dart';
import 'package:test/test.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../common/common.dart';

class FakeSink extends DelegatingStreamSink implements WebSocketSink {
  final FakeWebSocketChannel _channel;

  FakeSink(this._channel) : super(_channel._controller.sink);

  @override
  Future close([int? closeCode, String? closeReason]) async {
    await super.close();
    _channel._isClosed = true;
    _channel._closeCode = closeCode;
    _channel._closeReason = closeReason;
    await _channel._closed(closeCode, closeReason);
  }
}

class FakeWebSocketChannel extends StreamChannelMixin
    implements WebSocketChannel {
  final StreamChannel _controller;
  final Future Function(int? closeCode, String? closeReason) _closed;

  bool _isClosed = false;
  int? _closeCode;
  String? _closeReason;

  FakeWebSocketChannel(this._controller, this._closed);

  @override
  int? get closeCode => _closeCode;

  @override
  String? get closeReason => _closeReason;

  @override
  String? get protocol => throw UnimplementedError();

  @override
  Future<void> get ready => Future.value();

  @override
  WebSocketSink get sink => FakeSink(this);

  @override
  Stream get stream => _controller.stream;

  Future _remoteClosed(int closeCode, String? closeReason) async {
    if (!_isClosed) {
      await sink.close(closeCode, closeReason);
    }
  }
}

(WebSocketChannel, WebSocketChannel) createFakes() {
  final peer1Write = StreamController<dynamic>();
  final peer2Write = StreamController<dynamic>();

  late FakeWebSocketChannel foreign;
  late FakeWebSocketChannel local;

  foreign = FakeWebSocketChannel(
    StreamChannel(peer2Write.stream, peer1Write.sink),
    (closeCode, closeReason) =>
        local._remoteClosed(closeCode ?? 1005, closeReason),
  );
  local = FakeWebSocketChannel(
    StreamChannel(peer1Write.stream, peer2Write.sink),
    (closeCode, closeReason) =>
        foreign._remoteClosed(closeCode ?? 1005, closeReason),
  );

  return (foreign, local);
}

void main() {
  late ServeHandler serveHandler;
  late InternalTestReaderWriter readerWriter;
  late MockWatchImpl watchImpl;
  late PackageGraph packageGraph;
  late AssetGraph assetGraph;
  late BuildOutputReader finalizedReader;

  setUp(() async {
    packageGraph = buildPackageGraph({rootPackage('a'): []});
    readerWriter = InternalTestReaderWriter(
      rootPackage: packageGraph.currentPackage.name,
    );
    assetGraph = await AssetGraph.build(
      BuildPhases([]),
      <AssetId>{},
      packageGraph,
      readerWriter,
    );
    watchImpl = MockWatchImpl();
    serveHandler = ServeHandler(packageGraph.currentPackage.name, watchImpl);
    finalizedReader = BuildOutputReader.graphOnly(
      readerWriter: readerWriter,
      assetGraph: assetGraph,
    );
    watchImpl.addFutureResult(
      Future.value(
        BuildResult(
          status: BuildStatus.success,
          buildOutputReader: finalizedReader,
        ),
      ),
    );
  });

  void addSource(String id, String content, {bool deleted = false}) {
    final parsedId = AssetId.parse(id);
    var node = AssetNode.source(
      parsedId,
      digest: computeDigest(parsedId, content),
    );
    if (deleted) {
      node = node.rebuild((b) {
        b.deletedBy.add(
          PostProcessBuildStepId(input: node.id, actionNumber: 1),
        );
      });
    }
    assetGraph.add(node);
    readerWriter.testing.writeString(node.id, content);
  }

  test('can get handlers for a subdirectory', () async {
    addSource('a|web/index.html', 'content');
    final response = await serveHandler.handlerFor('web')(
      Request('GET', Uri.parse('http://server.com/index.html')),
    );
    expect(await response.readAsString(), 'content');
  });

  test('serves package files for /packages/<package name>', () async {
    addSource('a|lib/a.html', 'content');
    final response = await serveHandler.handlerFor('web')(
      Request('GET', Uri.parse('http://server.com/packages/a/a.html')),
    );
    expect(await response.readAsString(), 'content');
  });

  test('serves packages for /anywhere/packages/<package name>', () async {
    addSource('a|lib/a.html', 'content');
    final response = await serveHandler.handlerFor('web')(
      Request('GET', Uri.parse('http://server.com/anywhere/packages/a/a.html')),
    );
    expect(await response.readAsString(), 'content');
  });

  test('servers actual files before from packages for /packages/...', () async {
    // Match in `web` takes precedence over match in packages.
    addSource('a|lib/a.html', 'package_content');
    addSource('a|web/packages/a/a.html', 'web_content');
    final responseA = await serveHandler.handlerFor('web')(
      Request('GET', Uri.parse('http://server.com/packages/a/a.html')),
    );
    expect(await responseA.readAsString(), 'web_content');

    // Fall back to match in packages.
    addSource('b|lib/b.html', 'package_content');
    final responseB = await serveHandler.handlerFor('web')(
      Request('GET', Uri.parse('http://server.com/packages/b/b.html')),
    );
    expect(await responseB.readAsString(), 'package_content');
  });

  test(
    'serves index.html for actual folder called packages from /packages/`',
    () async {
      addSource('a|web/packages/index.html', 'content');
      final response = await serveHandler.handlerFor('web')(
        Request('GET', Uri.parse('http://server.com/packages/')),
      );
      expect(await response.readAsString(), 'content');
    },
  );

  test('serves nothing from /packages/` if missing', () async {
    final response = await serveHandler.handlerFor('web')(
      Request('GET', Uri.parse('http://server.com/packages/')),
    );
    expect(response.statusCode, HttpStatus.notFound);
  });

  test('caching with etags works', () async {
    addSource('a|web/index.html', 'content');
    final handler = serveHandler.handlerFor('web');
    final requestUri = Uri.parse('http://server.com/index.html');
    final firstResponse = await handler(Request('GET', requestUri));
    final etag = firstResponse.headers[HttpHeaders.etagHeader];
    expect(etag, isNotNull);
    expect(firstResponse.statusCode, HttpStatus.ok);
    expect(await firstResponse.readAsString(), 'content');

    final cachedResponse = await handler(
      Request(
        'GET',
        requestUri,
        headers: {HttpHeaders.ifNoneMatchHeader: etag!},
      ),
    );
    expect(cachedResponse.statusCode, HttpStatus.notModified);
    expect(await cachedResponse.readAsString(), isEmpty);
  });

  test('caching with etags takes into account injected JS', () async {
    addSource('a|web/some.js', '$entrypointExtensionMarker\nalert(1)');
    final noReloadEtag =
        (await serveHandler.handlerFor('web', liveReload: false)(
          Request('GET', Uri.parse('http://server.com/some.js')),
        )).headers[HttpHeaders.etagHeader];
    final liveReloadEtag =
        (await serveHandler.handlerFor('web', liveReload: true)(
          Request('GET', Uri.parse('http://server.com/some.js')),
        )).headers[HttpHeaders.etagHeader];
    expect(noReloadEtag, isNot(liveReloadEtag));
  });

  test('throws if you pass a non-root directory', () {
    expect(() => serveHandler.handlerFor('web/sub'), throwsArgumentError);
    expect(() => serveHandler.handlerFor('.'), throwsArgumentError);
  });

  group('build failures', () {
    setUp(() async {
      addSource('a|web/index.html', '');
      assetGraph.add(
        AssetNode.generated(
          AssetId('a', 'web/main.ddc.js'),
          phaseNumber: 0,
          isHidden: false,
          digest: Digest([]),
          result: false,
          primaryInput: AssetId('a', 'web/main.dart'),
        ),
      );
      watchImpl.addFutureResult(
        Future.value(
          BuildResult(
            status: BuildStatus.failure,
            buildOutputReader: finalizedReader,
          ),
        ),
      );
    });

    test('serves successful assets', () async {
      final response = await serveHandler.handlerFor('web')(
        Request('GET', Uri.parse('http://server.com/index.html')),
      );

      expect(response.statusCode, HttpStatus.ok);
    });

    test('rejects requests for failed assets', () async {
      final response = await serveHandler.handlerFor('web')(
        Request('GET', Uri.parse('http://server.com/main.ddc.js')),
      );

      expect(response.statusCode, HttpStatus.internalServerError);
    });

    test('logs rejected requests', () async {
      expect(
        Logger.root.onRecord,
        emitsThrough(
          predicate<LogRecord>(
            (record) =>
                record.message.contains('main.ddc.js') &&
                record.level == Level.WARNING,
          ),
        ),
      );
      await serveHandler.handlerFor('web', logRequests: true)(
        Request('GET', Uri.parse('http://server.com/main.ddc.js')),
      );
    });
  });

  test('logs requests if you ask it to', () async {
    addSource('a|web/index.html', 'content');
    expect(
      Logger.root.onRecord,
      emitsThrough(
        predicate<LogRecord>(
          (record) =>
              record.message.contains('index.html') &&
              record.level == Level.INFO,
        ),
      ),
    );
    await serveHandler.handlerFor('web', logRequests: true)(
      Request('GET', Uri.parse('http://server.com/index.html')),
    );
  });

  test('serve asset digests', () async {
    addSource('a|web/index.html', 'content1');
    addSource('a|lib/some.dart.js', 'content2');
    addSource('a|lib/another.dart.js', 'content3');
    final response = await serveHandler.handlerFor('web')(
      Request(
        'GET',
        Uri.parse('http://server.com/\$assetDigests'),
        body: jsonEncode([
          'index.html',
          'packages/a/some.dart.js',
          'packages/a/absent.dart.js',
        ]),
      ),
    );
    expect(jsonDecode(await response.readAsString()), {
      'index.html':
          computeDigest(AssetId('a', 'web/index.html'), 'content1').toString(),
      'packages/a/some.dart.js':
          computeDigest(
            AssetId('a', 'lib/some.dart.js'),
            'content2',
          ).toString(),
    });
  });

  group('build updates', () {
    void createBuildUpdatesGroup(
      String groupName,
      String injectionMarker, {
      required bool liveReload,
    }) => group(groupName, () {
      test('injects client code if enabled', () async {
        addSource('a|web/some.js', '$entrypointExtensionMarker\nalert(1)');
        final response = await serveHandler.handlerFor(
          'web',
          liveReload: liveReload,
        )(Request('GET', Uri.parse('http://server.com/some.js')));
        expect(await response.readAsString(), contains(injectionMarker));
      });

      test('doesn\'t inject client code if disabled', () async {
        addSource('a|web/some.js', '$entrypointExtensionMarker\nalert(1)');
        final response = await serveHandler.handlerFor('web')(
          Request('GET', Uri.parse('http://server.com/some.js')),
        );
        expect(await response.readAsString(), isNot(contains(injectionMarker)));
      });

      test('doesn\'t inject client code in non-js files', () async {
        addSource('a|web/some.html', '$entrypointExtensionMarker\n<br>some');
        final response = await serveHandler.handlerFor(
          'web',
          liveReload: liveReload,
        )(Request('GET', Uri.parse('http://server.com/some.html')));
        expect(await response.readAsString(), isNot(contains(injectionMarker)));
      });

      test('doesn\'t inject client code in non-marked files', () async {
        addSource('a|web/some.js', 'alert(1)');
        final response = await serveHandler.handlerFor(
          'web',
          liveReload: liveReload,
        )(Request('GET', Uri.parse('http://server.com/some.js')));
        expect(await response.readAsString(), isNot(contains(injectionMarker)));
      });

      test('expect websocket connection if enabled', () async {
        addSource('a|web/index.html', 'content');
        final uri = Uri.parse('ws://server.com/');
        expect(
          serveHandler.handlerFor('web', liveReload: liveReload)(
            Request(
              'GET',
              uri,
              headers: {
                'Connection': 'Upgrade',
                'Upgrade': 'websocket',
                'Sec-WebSocket-Version': '13',
                'Sec-WebSocket-Key': 'abc',
              },
              onHijack: (f) {},
            ),
          ),
          throwsA(const TypeMatcher<HijackException>()),
        );
      });
    });

    createBuildUpdatesGroup(
      'live-reload',
      'live_reload_client',
      liveReload: true,
    );

    test('reject websocket connection if disabled', () async {
      addSource('a|web/index.html', 'content');
      final response = await serveHandler.handlerFor('web')(
        Request(
          'GET',
          Uri.parse('ws://server.com/'),
          headers: {
            'Connection': 'Upgrade',
            'Upgrade': 'websocket',
            'Sec-WebSocket-Version': '13',
            'Sec-WebSocket-Key': 'abc',
          },
        ),
      );
      expect(response.statusCode, 200);
      expect(await response.readAsString(), 'content');
    });

    group('WebSocket handler', () {
      late BuildUpdatesWebSocketHandler handler;
      late Future<void> Function(WebSocketChannel, String) createMockConnection;

      late WebSocketChannel clientChannel1;
      late WebSocketChannel clientChannel2;
      late WebSocketChannel serverChannel1;
      late WebSocketChannel serverChannel2;

      setUp(() {
        Handler mockHandlerFactory(
          Function onConnect, {
          Iterable<String>? protocols,
        }) =>
            (Request request) =>
                Response(200, context: {'onConnect': onConnect});

        createMockConnection = (
          WebSocketChannel serverChannel,
          String rootDir,
        ) async {
          final mockResponse = await handler.createHandlerByRootDir(rootDir)(
            FakeRequest(),
          );
          final onConnect =
              mockResponse.context['onConnect']
                  as void Function(WebSocketChannel, String);
          onConnect(serverChannel, '');
        };

        handler = BuildUpdatesWebSocketHandler(mockHandlerFactory);

        (serverChannel1, clientChannel1) = createFakes();
        (serverChannel2, clientChannel2) = createFakes();
      });

      tearDown(() {
        serverChannel1.sink.close();
        clientChannel1.sink.close();
        serverChannel2.sink.close();
        clientChannel2.sink.close();
      });

      test('emits a message to all listeners', () async {
        expect(clientChannel1.stream, emitsInOrder(['{}', emitsDone]));
        expect(clientChannel2.stream, emitsInOrder(['{}', emitsDone]));
        await createMockConnection(serverChannel1, 'web');
        await createMockConnection(serverChannel2, 'web');
        await handler.emitUpdateMessage(
          BuildResult(
            status: BuildStatus.success,
            buildOutputReader: finalizedReader,
          ),
        );
        await clientChannel1.sink.close();
        await clientChannel2.sink.close();
      });

      test('deletes listeners on disconnect', () async {
        expect(clientChannel1.stream, emitsInOrder(['{}', '{}', emitsDone]));
        expect(clientChannel2.stream, emitsInOrder(['{}', emitsDone]));
        await createMockConnection(serverChannel1, 'web');
        await createMockConnection(serverChannel2, 'web');
        await handler.emitUpdateMessage(
          BuildResult(
            status: BuildStatus.success,
            buildOutputReader: finalizedReader,
          ),
        );
        await clientChannel2.sink.close();
        await handler.emitUpdateMessage(
          BuildResult(
            status: BuildStatus.success,
            buildOutputReader: finalizedReader,
          ),
        );
        await clientChannel1.sink.close();
      });

      test('emits only on successful builds', () async {
        expect(clientChannel1.stream, emitsDone);
        await createMockConnection(serverChannel1, 'web');
        await handler.emitUpdateMessage(
          BuildResult(
            status: BuildStatus.failure,
            buildOutputReader: finalizedReader,
          ),
        );
        await clientChannel1.sink.close();
      });

      test('closes listeners', () async {
        expect(clientChannel1.stream, emitsDone);
        await createMockConnection(serverChannel1, 'web');
        await handler.close();
        expect(clientChannel1.closeCode, isNotNull);
      });

      test('emits build results digests', () async {
        addSource('a|web/index.html', 'content1');
        addSource('a|lib/some.dart.js', 'content2');
        final indexHash =
            computeDigest(
              AssetId('a', 'web/index.html'),
              'content1',
            ).toString();
        expect(
          clientChannel1.stream.map((s) => jsonDecode(s.toString())),
          emitsInOrder([
            {'index.html': indexHash},
            {
              'index.html': indexHash,
              'packages/a/some.dart.js':
                  computeDigest(
                    AssetId('a', 'lib/some.dart.js'),
                    'content2',
                  ).toString(),
            },
            emitsDone,
          ]),
        );
        await createMockConnection(serverChannel1, 'web');
        await handler.emitUpdateMessage(
          BuildResult(
            status: BuildStatus.success,
            outputs: [AssetId('a', 'web/index.html')].build(),
            buildOutputReader: finalizedReader,
          ),
        );
        await handler.emitUpdateMessage(
          BuildResult(
            status: BuildStatus.success,
            outputs:
                [
                  AssetId('a', 'web/index.html'),
                  AssetId('a', 'lib/some.dart.js'),
                ].build(),
            buildOutputReader: finalizedReader,
          ),
        );
        await clientChannel1.sink.close();
      });

      test('works for different root dirs', () async {
        addSource('a|web1/index.html', 'content1');
        addSource('a|web2/index.html', 'content2');
        addSource('a|lib/some.dart.js', 'content3');
        final someDartHash =
            computeDigest(
              AssetId('a', 'lib/some.dart.js'),
              'content3',
            ).toString();
        expect(
          clientChannel1.stream.map((s) => jsonDecode(s.toString())),
          emitsInOrder([
            {
              'index.html':
                  computeDigest(
                    AssetId('a', 'web1/index.html'),
                    'content1',
                  ).toString(),
              'packages/a/some.dart.js': someDartHash,
            },
            emitsDone,
          ]),
        );
        expect(
          clientChannel2.stream.map((s) => jsonDecode(s.toString())),
          emitsInOrder([
            {
              'index.html':
                  computeDigest(
                    AssetId('a', 'web2/index.html'),
                    'content2',
                  ).toString(),
              'packages/a/some.dart.js': someDartHash,
            },
            emitsDone,
          ]),
        );
        await createMockConnection(serverChannel1, 'web1');
        await createMockConnection(serverChannel2, 'web2');
        await handler.emitUpdateMessage(
          BuildResult(
            status: BuildStatus.success,
            outputs:
                [
                  AssetId('a', 'web1/index.html'),
                  AssetId('a', 'web2/index.html'),
                  AssetId('a', 'lib/some.dart.js'),
                ].build(),
            buildOutputReader: finalizedReader,
          ),
        );
        await clientChannel1.sink.close();
        await clientChannel2.sink.close();
      });
    });
  });
}

class MockWatchImpl implements Watcher {
  Future<BuildResult>? _currentBuild;

  @override
  Future<BuildResult> get currentBuildResult => _currentBuild!;

  final _futureBuildResultsController = StreamController<Future<BuildResult>>();
  final _buildResultsController = StreamController<BuildResult>();

  @override
  Stream<BuildResult> get buildResults => _buildResultsController.stream;

  void addFutureResult(Future<BuildResult> result) {
    _futureBuildResultsController.add(result);
  }

  MockWatchImpl() {
    final firstBuild = Completer<BuildResult>();
    _currentBuild = firstBuild.future;
    _futureBuildResultsController.stream.listen((futureBuildResult) {
      if (!firstBuild.isCompleted) {
        firstBuild.complete(futureBuildResult);
      }
      _currentBuild = _currentBuild!.then((_) => futureBuildResult)
        ..then(_buildResultsController.add);
    });
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeRequest with Fake implements Request {}
