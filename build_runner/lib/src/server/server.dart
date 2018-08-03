// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:build/build.dart';
import 'package:build_runner_core/build_runner_core.dart';
import 'package:glob/glob.dart';
import 'package:logging/logging.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../generate/watch_impl.dart';
import 'asset_graph_handler.dart';
import 'path_to_asset_id.dart';

const _performancePath = r'$perf';
final _graphPath = r'$graph';
final _buildUpdatesProtocol = r'$livereload';
final _buildUpdatesMessage = 'update';
final _entrypointExtensionMarker = '/* ENTRYPOINT_EXTENTION_MARKER */';

final _logger = new Logger('Serve');

ServeHandler createServeHandler(WatchImpl watch) {
  var rootPackage = watch.packageGraph.root.name;
  var assetGraphHanderCompleter = new Completer<AssetGraphHandler>();
  var assetHandlerCompleter = new Completer<AssetHandler>();
  watch.ready.then((_) async {
    assetHandlerCompleter.complete(new AssetHandler(watch.reader, rootPackage));
    assetGraphHanderCompleter.complete(
        new AssetGraphHandler(watch.reader, rootPackage, watch.assetGraph));
  });
  return new ServeHandler._(watch, assetHandlerCompleter.future,
      assetGraphHanderCompleter.future, rootPackage);
}

class ServeHandler implements BuildState {
  final WatchImpl _state;
  BuildResult _lastBuildResult;
  final String _rootPackage;

  final Future<AssetHandler> _assetHandler;
  final Future<AssetGraphHandler> _assetGraphHandler;

  final _webSocketHandler = BuildUpdatesWebSocketHandler();

  ServeHandler._(this._state, this._assetHandler, this._assetGraphHandler,
      this._rootPackage) {
    _state.buildResults.listen((result) {
      _lastBuildResult = result;
      _webSocketHandler.emitUpdateMessage(result);
    });
  }

  @override
  Future<BuildResult> get currentBuild => _state.currentBuild;
  @override
  Stream<BuildResult> get buildResults => _state.buildResults;

  shelf.Handler handlerFor(String rootDir,
      {bool logRequests, bool liveReload}) {
    liveReload ??= false;
    logRequests ??= false;
    if (p.url.split(rootDir).length != 1) {
      throw new ArgumentError.value(
          rootDir, 'rootDir', 'Only top level directories are supported');
    }
    _state.currentBuild.then((_) => _warnForEmptyDirectory(rootDir));
    var cascade = new shelf.Cascade();
    cascade = (liveReload ? cascade.add(_webSocketHandler.handler) : cascade)
        .add(_blockOnCurrentBuild)
        .add((shelf.Request request) async {
      if (request.url.path == _performancePath) {
        return _performanceHandler(request);
      }
      if (request.url.path.startsWith(_graphPath)) {
        var graphHandler = await _assetGraphHandler;
        return await graphHandler.handle(
            request.change(path: _graphPath), rootDir);
      }
      var assetHandler = await _assetHandler;
      return assetHandler.handle(request, rootDir);
    });
    var pipeline = shelf.Pipeline();
    if (logRequests) {
      pipeline = pipeline.addMiddleware(_logRequests);
    }
    if (liveReload) {
      pipeline = pipeline.addMiddleware(_injectBuildUpdatesClientCode);
    }
    return pipeline.addHandler(cascade.handler);
  }

  Future<shelf.Response> _blockOnCurrentBuild(_) async {
    await currentBuild;
    return new shelf.Response.notFound('');
  }

  shelf.Response _performanceHandler(shelf.Request request) {
    var hideSkipped = false;
    if (request.url.queryParameters['hideSkipped']?.toLowerCase() == 'true') {
      hideSkipped = true;
    }
    return new shelf.Response.ok(
        _renderPerformance(_lastBuildResult.performance, hideSkipped),
        headers: {HttpHeaders.contentTypeHeader: 'text/html'});
  }

  void _warnForEmptyDirectory(String rootDir) {
    if (!_state.assetGraph
        .packageNodes(_rootPackage)
        .any((n) => n.id.path.startsWith('$rootDir/'))) {
      _logger.warning('Requested a server for `$rootDir` but this directory '
          'has no assets in the build. You may need to add some sources or '
          'include this directory in some target in your `build.yaml`');
    }
  }
}

/// Class that manages web socket connection handler to inform clients about
/// build updates
class BuildUpdatesWebSocketHandler {
  final activeConnections = <WebSocketChannel>[];
  final Function _handlerFactory;
  shelf.Handler _internalHandler;

  BuildUpdatesWebSocketHandler([this._handlerFactory = webSocketHandler]) {
    var untypedTearOff = (webSocket, protocol) =>
        _handleConnection(webSocket as WebSocketChannel, protocol as String);
    _internalHandler =
        _handlerFactory(untypedTearOff, protocols: [_buildUpdatesProtocol])
            as shelf.Handler;
  }

  shelf.Handler get handler => _internalHandler;

  void emitUpdateMessage(BuildResult buildResult) {
    for (var webSocket in activeConnections) {
      webSocket.sink.add(_buildUpdatesMessage);
    }
  }

  void _handleConnection(WebSocketChannel webSocket, String protocol) async {
    activeConnections.add(webSocket);
    await webSocket.stream.drain();
    activeConnections.remove(webSocket);
  }
}

shelf.Handler _injectBuildUpdatesClientCode(shelf.Handler innerHandler) {
  return (shelf.Request request) async {
    if (!request.url.path.endsWith('.js')) {
      return innerHandler(request);
    }
    var response = await innerHandler(request);
    // TODO: Find a way how to check and/or modify body without reading it whole
    var body = await response.readAsString();
    if (body.startsWith(_entrypointExtensionMarker)) {
      body += _buildUpdatesInjectedJS;
    }
    return response.change(body: body);
  };
}

/// Hot-reload config
///
/// Listen WebSocket for updates in build results
///
/// Now only live-reload functional - just reload page on update message
final _buildUpdatesInjectedJS = '''\n
(function() {
  var ws = new WebSocket('ws://' + location.host, ['$_buildUpdatesProtocol']);
  ws.onmessage = function(event) {
    console.log(event);
    if(event.data === '$_buildUpdatesMessage'){
      location.reload();
    }
  };
}());
''';

class AssetHandler {
  final FinalizedReader _reader;
  final String _rootPackage;

  final _typeResolver = new MimeTypeResolver();

  AssetHandler(this._reader, this._rootPackage);

  Future<shelf.Response> handle(shelf.Request request, String rootDir) =>
      (request.url.path.endsWith('/') || request.url.path.isEmpty)
          ? _handle(
              request.headers,
              pathToAssetId(
                  _rootPackage,
                  rootDir,
                  request.url.pathSegments
                      .followedBy(const ['index.html']).toList()),
              fallbackToDirectoryList: true)
          : _handle(request.headers,
              pathToAssetId(_rootPackage, rootDir, request.url.pathSegments));

  Future<shelf.Response> _handle(
      Map<String, String> requestHeaders, AssetId assetId,
      {bool fallbackToDirectoryList = false}) async {
    try {
      if (!await _reader.canRead(assetId)) {
        var reason = await _reader.unreadableReason(assetId);
        switch (reason) {
          case UnreadableReason.failed:
            return new shelf.Response.internalServerError(
                body: 'Build failed for $assetId');
          case UnreadableReason.notOutput:
            return new shelf.Response.notFound('$assetId was not output');
          case UnreadableReason.notFound:
            if (fallbackToDirectoryList) {
              return new shelf.Response.notFound(
                  await _findDirectoryList(assetId));
            }
            return new shelf.Response.notFound('Not Found');
          default:
            return new shelf.Response.notFound('Not Found');
        }
      }
    } on ArgumentError catch (_) {
      return new shelf.Response.notFound('Not Found');
    }

    var etag = base64.encode((await _reader.digest(assetId)).bytes);
    var headers = {
      HttpHeaders.contentTypeHeader: _typeResolver.lookup(assetId.path),
      HttpHeaders.etagHeader: etag,
      // We always want this revalidated, which requires specifying both
      // max-age=0 and must-revalidate.
      //
      // See spec https://goo.gl/Lhvttg for more info about this header.
      HttpHeaders.cacheControlHeader: 'max-age=0, must-revalidate',
    };

    if (requestHeaders[HttpHeaders.ifNoneMatchHeader] == etag) {
      // This behavior is still useful for cases where a file is hit
      // without a cache-busting query string.
      return new shelf.Response.notModified(headers: headers);
    }

    var bytes = await _reader.readAsBytes(assetId);
    headers[HttpHeaders.contentLengthHeader] = '${bytes.length}';
    return new shelf.Response.ok(bytes, headers: headers);
  }

  Future<String> _findDirectoryList(AssetId from) async {
    var directoryPath = p.url.dirname(from.path);
    var glob = p.url.join(directoryPath, '*');
    var result =
        await _reader.findAssets(new Glob(glob)).map((a) => a.path).toList();
    return (result.isEmpty)
        ? 'Could not find ${from.path} or any files in $directoryPath.'
        : 'Could not find ${from.path}. $directoryPath contains:\n'
        '${result.join('\n')}';
  }
}

String _renderPerformance(BuildPerformance performance, bool hideSkipped) {
  try {
    var rows = new StringBuffer();
    for (var action in performance.actions) {
      if (hideSkipped &&
          !action.phases.any((phase) => phase.label == 'Build')) {
        continue;
      }
      var actionKey = '${action.builderKey}:${action.primaryInput}';
      for (var phase in action.phases) {
        var start = phase.startTime.millisecondsSinceEpoch -
            performance.startTime.millisecondsSinceEpoch;
        var end = phase.stopTime.millisecondsSinceEpoch -
            performance.startTime.millisecondsSinceEpoch;

        rows.writeln(
            '          ["$actionKey", "${phase.label}", $start, $end],');
      }
    }
    if (performance.duration < new Duration(seconds: 1)) {
      rows.writeln('          ['
          '"https://github.com/google/google-visualization-issues/issues/2269"'
          ', "", 0, 1000]');
    }

    var showSkippedHref = hideSkipped
        ? '/$_performancePath'
        : '/$_performancePath?hideSkipped=true';
    var showSkippedText =
        hideSkipped ? 'Show Skipped Actions' : 'Hide Skipped Actions';
    var showSkippedLink = '<a href="$showSkippedHref">$showSkippedText</a>';
    return '''
  <html>
    <head>
      <script src="https://www.gstatic.com/charts/loader.js"></script>
      <script>
        google.charts.load('current', {'packages':['timeline']});
        google.charts.setOnLoadCallback(drawChart);
        function drawChart() {
          var container = document.getElementById('timeline');
          var chart = new google.visualization.Timeline(container);
          var dataTable = new google.visualization.DataTable();

          dataTable.addColumn({ type: 'string', id: 'ActionKey' });
          dataTable.addColumn({ type: 'string', id: 'Phase' });
          dataTable.addColumn({ type: 'number', id: 'Start' });
          dataTable.addColumn({ type: 'number', id: 'End' });
          dataTable.addRows([
  $rows
          ]);

          var options = {
            colors: ['#cbb69d', '#603913', '#c69c6e']
          };
          var statusText = document.getElementById('status');
          var timeoutId;
          var updateFunc = function () {
              if (timeoutId) {
                  // don't schedule more than one at a time
                  return;
              }
              statusText.innerText = 'Drawing table...';
              console.time('draw-time');

              timeoutId = setTimeout(function () {
                  chart.draw(dataTable, options);
                  console.timeEnd('draw-time');
                  statusText.innerText = '';
                  timeoutId = null;
              });
          };

          updateFunc();

          window.addEventListener('resize', updateFunc);
        }
      </script>
      <style>
      html, body {
        width: 100%;
        height: 100%;
        margin: 0;
      }

      body {
        display: flex;
        flex-direction: column;
      }

      #timeline {
        display: flex;
        flex-direction: row;
        flex: 1;
      }
      .controls-header p {
        display: inline-block;
        margin: 0.5em;
      }
      </style>
    </head>
    <body>
      <div class="controls-header">
        <p>$showSkippedLink</p>
        <p id="status"></p>
      </div>
      <div id="timeline"></div>
    </body>
  </html>
  ''';
  } on UnimplementedError catch (_) {
    return '''
<html>
  <body>
    <p>
      Performance information not available, you must pass the
      `--track-performance` command line arg to enable performance tracking.
    </p>
  <body>
</html>
''';
  }
}

/// [shelf.Middleware] that logs all requests, inspired by [shelf.logRequests].
shelf.Handler _logRequests(shelf.Handler innerHandler) {
  return (shelf.Request request) {
    var startTime = new DateTime.now();
    var watch = new Stopwatch()..start();

    return new Future.sync(() => innerHandler(request)).then((response) {
      var logFn = response.statusCode >= 500 ? _logger.warning : _logger.info;
      var msg = _getMessage(startTime, response.statusCode,
          request.requestedUri, request.method, watch.elapsed);
      logFn(msg);
      return response;
    }, onError: (error, stackTrace) {
      if (error is shelf.HijackException) throw error;
      var msg = _getMessage(
          startTime, 500, request.requestedUri, request.method, watch.elapsed);
      _logger.severe('$msg\r\n$error\r\n$stackTrace', true);
      throw error;
    });
  };
}

String _getMessage(DateTime requestTime, int statusCode, Uri requestedUri,
    String method, Duration elapsedTime) {
  return '${requestTime.toIso8601String()} '
      '${humanReadable(elapsedTime)} '
      '$method [$statusCode] '
      '${requestedUri.path}${_formatQuery(requestedUri.query)}\r\n';
}

String _formatQuery(String query) {
  return query == '' ? '' : '?$query';
}
