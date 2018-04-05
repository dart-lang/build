// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:build/build.dart';
import 'package:logging/logging.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart' as shelf;

import '../asset/finalized_reader.dart';
import '../generate/build_result.dart';
import '../generate/performance_tracker.dart';
import '../generate/watch_impl.dart';
import '../logging/human_readable_duration.dart';
import 'asset_graph_handler.dart';
import 'path_to_asset_id.dart';

const _performancePath = r'$perf';

final _logger = new Logger('Serve');

Future<ServeHandler> createServeHandler(WatchImpl watch) async {
  var rootPackage = watch.packageGraph.root.name;
  var reader = await watch.reader;
  var assetHandler = new AssetHandler(reader, rootPackage);
  var assetGraphHandler =
      new AssetGraphHandler(reader, rootPackage, watch.assetGraph);
  return new ServeHandler._(
      watch, assetHandler, assetGraphHandler, reader, rootPackage);
}

class ServeHandler implements BuildState {
  final BuildState _state;
  BuildResult _lastBuildResult;
  final AssetReader _reader;
  final String _rootPackage;

  final AssetHandler _assetHandler;
  final AssetGraphHandler _assetGraphHandler;

  ServeHandler._(this._state, this._assetHandler, this._assetGraphHandler,
      this._reader, this._rootPackage) {
    _state.buildResults.listen((result) {
      _lastBuildResult = result;
    });
  }

  @override
  Future<BuildResult> get currentBuild => _state.currentBuild;
  @override
  Stream<BuildResult> get buildResults => _state.buildResults;

  shelf.Handler handlerFor(String rootDir, {bool logRequests}) {
    logRequests ??= false;
    if (p.url.split(rootDir).length != 1) {
      throw new ArgumentError.value(
          rootDir, 'rootDir', 'Only top level directories are supported');
    }
    var cascade = new shelf.Cascade()
        .add(_blockOnCurrentBuild)
        .add((shelf.Request request) {
      if (request.url.path == _performancePath) {
        return _performanceHandler(request);
      }
      if (request.url.path.startsWith(r'$graph')) {
        return _assetGraphHandler.handle(request, rootDir);
      }
      return _assetHandler.handle(request, rootDir);
    });
    var handler = logRequests
        ? const shelf.Pipeline()
            .addMiddleware(_logRequests)
            .addHandler(cascade.handler)
        : cascade.handler;
    return handler;
  }

  FutureOr<shelf.Response> _blockOnCurrentBuild(_) async {
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
        headers: {HttpHeaders.CONTENT_TYPE: 'text/html'});
  }
}

class AssetHandler {
  final FinalizedReader _reader;
  final String _rootPackage;

  final _typeResolver = new MimeTypeResolver();

  AssetHandler(this._reader, this._rootPackage);

  Future<shelf.Response> handle(shelf.Request request, String rootDir) {
    var pathSegments =
        (request.url.path.endsWith('/') || request.url.path.isEmpty)
            ? request.url.pathSegments.followedBy(const ['index.html']).toList()
            : request.url.pathSegments;
    return _handle(
        request.headers, pathToAssetId(_rootPackage, rootDir, pathSegments));
  }

  Future<shelf.Response> _handle(
      Map<String, String> requestHeaders, AssetId assetId) async {
    try {
      if (!await _reader.canRead(assetId)) {
        var reason = await _reader.unreadableReason(assetId);
        switch (reason) {
          case UnreadableReason.failed:
            return new shelf.Response.internalServerError(
                body: 'Build failed for $assetId');
          case UnreadableReason.notOutput:
            return new shelf.Response.notFound('$assetId was not output');
          default:
            return new shelf.Response.notFound('Not Found');
        }
      }
    } on ArgumentError catch (_) {
      return new shelf.Response.notFound('Not Found');
    }

    var etag = base64.encode((await _reader.digest(assetId)).bytes);
    var headers = {
      HttpHeaders.CONTENT_TYPE: _typeResolver.lookup(assetId.path),
      HttpHeaders.ETAG: etag,
      // We always want this revalidated, which requires specifying both
      // max-age=0 and must-revalidate.
      //
      // See spec https://goo.gl/Lhvttg for more info about this header.
      HttpHeaders.CACHE_CONTROL: 'max-age=0, must-revalidate',
    };

    if (requestHeaders[HttpHeaders.IF_NONE_MATCH] == etag) {
      // This behavior is still useful for cases where a file is hit
      // without a cache-busting query string.
      return new shelf.Response.notModified(headers: headers);
    }

    var bytes = await _reader.readAsBytes(assetId);
    headers[HttpHeaders.CONTENT_LENGTH] = '${bytes.length}';
    return new shelf.Response.ok(bytes, headers: headers);
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
      var actionKey = '${action.builder.runtimeType}:${action.primaryInput}';
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
