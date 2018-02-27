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

import '../asset_graph/graph.dart';
import '../generate/build_result.dart';
import '../generate/performance_tracker.dart';
import '../generate/watch_impl.dart';
import '../logging/human_readable_duration.dart';

const _performancePath = r'$perf';
const _assetGraphVisualizationPath = r'$graph';
const _assetGraphPath = r'$graph/assets.json';

final _logger = new Logger('Serve');

Future<ServeHandler> createServeHandler(WatchImpl watch) async {
  var rootPackage = watch.packageGraph.root.name;
  var reader = await watch.reader;
  var assetHandler = new AssetHandler(reader, rootPackage);
  return new ServeHandler._(watch, assetHandler, watch.assetGraph, reader);
}

class ServeHandler implements BuildState {
  final BuildState _state;
  final AssetHandler _assetHandler;
  BuildResult _lastBuildResult;
  final AssetGraph _assetGraph;
  final AssetReader _reader;

  ServeHandler._(
      this._state, this._assetHandler, this._assetGraph, this._reader) {
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
        .add(_assetGraphVisualizationHandler)
        .add(_assetGraphHandler)
        .add(_performanceHandler)
        .add((shelf.Request request) => _handle(request, rootDir));
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

  FutureOr<shelf.Response> _assetGraphVisualizationHandler(
      shelf.Request request) async {
    if (request.url.path != _assetGraphVisualizationPath) {
      return new shelf.Response.notFound('');
    }

    return new shelf.Response.ok(
        await _reader.readAsString(
            new AssetId('build_runner', 'lib/src/server/graph_viz.html')),
        headers: {HttpHeaders.CONTENT_TYPE: 'text/html'});
  }

  FutureOr<shelf.Response> _assetGraphHandler(shelf.Request request) async {
    if (request.url.path != _assetGraphPath)
      return new shelf.Response.notFound('');
    var jsonContent = UTF8.decode(_assetGraph.serialize());
    return new shelf.Response.ok(jsonContent,
        headers: {HttpHeaders.CONTENT_TYPE: 'application/json'});
  }

  FutureOr<shelf.Response> _performanceHandler(shelf.Request request) async {
    if (request.url.path != _performancePath) {
      return new shelf.Response.notFound('');
    }
    bool hideSkipped = false;
    if (request.url.queryParameters['hideSkipped']?.toLowerCase() == 'true') {
      hideSkipped = true;
    }
    return new shelf.Response.ok(
        _renderPerformance(_lastBuildResult.performance, hideSkipped),
        headers: {HttpHeaders.CONTENT_TYPE: 'text/html'});
  }

  FutureOr<shelf.Response> _handle(
      shelf.Request request, String rootDir) async {
    if (_lastBuildResult.status == BuildStatus.failure) {
      return new shelf.Response(HttpStatus.INTERNAL_SERVER_ERROR,
          body: _htmlErrorPage(_lastBuildResult),
          headers: {HttpHeaders.CONTENT_TYPE: 'text/html'});
    }
    return _assetHandler.handle(request, rootDir);
  }

  static String _htmlErrorPage(BuildResult result) => '<h1>Build failed!</h1>'
      '<p><strong>Error:</strong></p>'
      '<p><strong style="color: red">'
      '${_htmlify(result.exception)}'
      '</strong></p>'
      '<p><strong>Stack Trace:</strong></p>'
      '<p>${_htmlify(result.stackTrace)}</p>';

  static String _htmlify(content) =>
      content.toString().replaceAll('\n', '<br/>').replaceAll(' ', '&nbsp;');
}

class AssetHandler {
  final AssetReader _reader;
  final String _rootPackage;

  final _typeResolver = new MimeTypeResolver();

  AssetHandler(this._reader, this._rootPackage);

  Future<shelf.Response> handle(shelf.Request request, String rootDir) {
    var pathSegments = <String>[rootDir];
    pathSegments.addAll(request.url.pathSegments);

    if (request.url.path.endsWith('/') || request.url.path.isEmpty) {
      pathSegments = new List.from(pathSegments)..add('index.html');
    }
    return _handle(request.headers, pathSegments);
  }

  Future<shelf.Response> _handle(
      Map<String, String> requestHeaders, List<String> pathSegments) async {
    var packagesIndex = pathSegments.indexOf('packages');
    var assetId = packagesIndex >= 0
        ? new AssetId(pathSegments[packagesIndex + 1],
            p.join('lib', p.joinAll(pathSegments.sublist(packagesIndex + 2))))
        : new AssetId(_rootPackage, p.joinAll(pathSegments));
    try {
      if (!await _reader.canRead(assetId)) {
        return new shelf.Response.notFound('Not Found');
      }
    } on ArgumentError catch (_) {
      return new shelf.Response.notFound('Not Found');
    }

    var etag = BASE64.encode((await _reader.digest(assetId)).bytes);
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
        hideSkipped ? "Show Skipped Actions" : "Hide Skipped Actions";
    var showSkippedLink = '<a href="$showSkippedHref">$showSkippedText</a>';
    return '''
  <html>
    <head>
      <script type="text/javascript" src="https://www.gstatic.com/charts/loader.js"></script>
      <script type="text/javascript">
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
          chart.draw(dataTable, options);
        }
      </script>
    </head>
    <body>
      <p>$showSkippedLink</p>
      <div id="timeline" style="height: 100%"></div>
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
