// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:build/build.dart';
import 'package:build_runner_core/build_runner_core.dart';
import 'package:crypto/crypto.dart';
import 'package:glob/glob.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../entrypoint/options.dart';
import '../generate/watch_impl.dart';
import 'path_to_asset_id.dart';

final _assetsDigestPath = r'$assetDigests';
final _buildUpdatesProtocol = r'$buildUpdates';
final entrypointExtensionMarker = '/* ENTRYPOINT_EXTENTION_MARKER */';

enum PerfSortOrder {
  startTimeAsc,
  startTimeDesc,
  stopTimeAsc,
  stopTimeDesc,
  durationAsc,
  durationDesc,
  innerDurationAsc,
  innerDurationDesc,
}

ServeHandler createServeHandler(WatchImpl watch) {
  var rootPackage = watch.packageGraph.root.name;
  var assetHandlerCompleter = Completer<AssetHandler>();
  watch.reader
      .then((reader) async {
        assetHandlerCompleter.complete(AssetHandler(reader, rootPackage));
      })
      .catchError((_) {}); // These errors are separately handled.
  return ServeHandler._(watch, assetHandlerCompleter.future, rootPackage);
}

class ServeHandler implements BuildState {
  final WatchImpl _state;
  final String _rootPackage;

  final Future<AssetHandler> _assetHandler;

  final BuildUpdatesWebSocketHandler _webSocketHandler;

  ServeHandler._(this._state, this._assetHandler, this._rootPackage)
    : _webSocketHandler = BuildUpdatesWebSocketHandler(_state) {
    _state.buildResults
        .listen(_webSocketHandler.emitUpdateMessage)
        .onDone(_webSocketHandler.close);
  }

  @override
  Future<BuildResult>? get currentBuild => _state.currentBuild;

  @override
  Stream<BuildResult> get buildResults => _state.buildResults;

  shelf.Handler handlerFor(
    String rootDir, {
    bool logRequests = false,
    BuildUpdatesOption buildUpdates = BuildUpdatesOption.none,
  }) {
    if (p.url.split(rootDir).length != 1 || rootDir == '.') {
      throw ArgumentError.value(
        rootDir,
        'directory',
        'Only top level directories such as `web` or `test` can be served, got',
      );
    }
    _state.currentBuild?.then((_) {
      // If the first build fails with a handled exception, we might not have
      // an asset graph and can't do this check.
      if (_state.assetGraph == null) return;
      _warnForEmptyDirectory(rootDir);
    });
    var cascade = shelf.Cascade();
    if (buildUpdates != BuildUpdatesOption.none) {
      cascade = cascade.add(_webSocketHandler.createHandlerByRootDir(rootDir));
    }
    cascade = cascade.add(_blockOnCurrentBuild).add((
      shelf.Request request,
    ) async {
      if (request.url.path == _assetsDigestPath) {
        return _assetsDigestHandler(request, rootDir);
      }
      var assetHandler = await _assetHandler;
      return assetHandler.handle(request, rootDir: rootDir);
    });
    var pipeline = const shelf.Pipeline();
    if (logRequests) {
      pipeline = pipeline.addMiddleware(_logRequests);
    }
    switch (buildUpdates) {
      case BuildUpdatesOption.liveReload:
        pipeline = pipeline.addMiddleware(_injectLiveReloadClientCode);
        break;
      case BuildUpdatesOption.none:
        break;
    }
    return pipeline.addHandler(cascade.handler);
  }

  Future<shelf.Response> _blockOnCurrentBuild(void _) async {
    await currentBuild;
    return shelf.Response.notFound('');
  }

  Future<shelf.Response> _assetsDigestHandler(
    shelf.Request request,
    String rootDir,
  ) async {
    final reader = await _state.reader;
    var assertPathList =
        (jsonDecode(await request.readAsString()) as List).cast<String>();
    var rootPackage = _state.packageGraph.root.name;
    var results = <String, String>{};
    for (final path in assertPathList) {
      try {
        var assetId = pathToAssetId(rootPackage, rootDir, p.url.split(path));
        var digest = await reader.digest(assetId);
        results[path] = digest.toString();
      } on AssetNotFoundException {
        results.remove(path);
      }
    }
    return shelf.Response.ok(
      jsonEncode(results),
      headers: {HttpHeaders.contentTypeHeader: 'application/json'},
    );
  }

  void _warnForEmptyDirectory(String rootDir) {
    if (!_state.assetGraph!
        .packageNodes(_rootPackage)
        .any((n) => n.id.path.startsWith('$rootDir/'))) {
      buildLog.warning(
        'Requested a server for `$rootDir` but this directory '
        'has no assets in the build. You may need to add some sources or '
        'include this directory in some target in your `build.yaml`.',
      );
    }
  }
}

/// Class that manages web socket connection handler to inform clients about
/// build updates
class BuildUpdatesWebSocketHandler {
  final connectionsByRootDir = <String, List<WebSocketChannel>>{};
  final shelf.Handler Function(
    void Function(WebSocketChannel webSocket, String? subprotocol), {
    Iterable<String> protocols,
  })
  _handlerFactory;
  final _internalHandlers = <String, shelf.Handler>{};
  final WatchImpl _state;

  BuildUpdatesWebSocketHandler(
    this._state, [
    this._handlerFactory = webSocketHandler,
  ]);

  shelf.Handler createHandlerByRootDir(String rootDir) {
    if (!_internalHandlers.containsKey(rootDir)) {
      void closureForRootDir(WebSocketChannel webSocket, String? protocol) =>
          _handleConnection(webSocket, protocol, rootDir);
      _internalHandlers[rootDir] = _handlerFactory(
        closureForRootDir,
        protocols: [_buildUpdatesProtocol],
      );
    }
    return _internalHandlers[rootDir]!;
  }

  Future emitUpdateMessage(BuildResult buildResult) async {
    if (buildResult.status != BuildStatus.success) return;
    final reader = await _state.reader;
    final digests = <AssetId, String>{};
    for (var assetId in buildResult.outputs) {
      var digest = await reader.digest(assetId);
      digests[assetId] = digest.toString();
    }
    for (var rootDir in connectionsByRootDir.keys) {
      var resultMap = <String, String?>{};
      for (var assetId in digests.keys) {
        var path = assetIdToPath(assetId, rootDir);
        if (path != null) {
          resultMap[path] = digests[assetId];
        }
      }
      for (var connection in connectionsByRootDir[rootDir]!) {
        connection.sink.add(jsonEncode(resultMap));
      }
    }
  }

  void _handleConnection(
    WebSocketChannel webSocket,
    String? protocol,
    String rootDir,
  ) async {
    var connections = connectionsByRootDir.putIfAbsent(rootDir, () => [])
      ..add(webSocket);
    await webSocket.stream.drain<void>();
    connections.remove(webSocket);
    if (connections.isEmpty) {
      connectionsByRootDir.remove(rootDir);
    }
  }

  Future<void> close() {
    return Future.wait(
      connectionsByRootDir.values
          .expand((x) => x)
          .map((connection) => connection.sink.close()),
    );
  }
}

shelf.Handler Function(shelf.Handler) _injectBuildUpdatesClientCode(
  String scriptName,
) => (innerHandler) {
  return (shelf.Request request) async {
    if (!request.url.path.endsWith('.js')) {
      return innerHandler(request);
    }
    var response = await innerHandler(request);
    // TODO: Find a way how to check and/or modify body without reading it
    // whole.
    var body = await response.readAsString();
    if (body.startsWith(entrypointExtensionMarker)) {
      body += _buildUpdatesInjectedJS(scriptName);
      var originalEtag = response.headers[HttpHeaders.etagHeader];
      if (originalEtag != null) {
        var newEtag = base64.encode(md5.convert(body.codeUnits).bytes);
        var newHeaders = Map.of(response.headers);
        newHeaders[HttpHeaders.etagHeader] = newEtag;

        if (request.headers[HttpHeaders.ifNoneMatchHeader] == newEtag) {
          return shelf.Response.notModified(headers: newHeaders);
        }

        response = response.change(headers: newHeaders);
      }
    }
    return response.change(body: body);
  };
};

final _injectLiveReloadClientCode = _injectBuildUpdatesClientCode(
  'live_reload_client',
);

/// Hot-/live- reload config
///
/// Listen WebSocket for updates in build results
String _buildUpdatesInjectedJS(String scriptName) => '''\n
// Injected by build_runner for build updates support
window.\$dartLoader.forceLoadModule('packages/build_runner/src/server/build_updates_client/$scriptName');
''';

class AssetHandler {
  final FinalizedReader _reader;
  final String _rootPackage;

  final _typeResolver = MimeTypeResolver();

  AssetHandler(this._reader, this._rootPackage);

  Future<shelf.Response> handle(shelf.Request request, {String rootDir = ''}) =>
      (request.url.path.endsWith('/') || request.url.path.isEmpty)
          ? _handle(
            request,
            pathToAssetId(_rootPackage, rootDir, [
              ...request.url.pathSegments,
              'index.html',
            ]),
            fallbackToDirectoryList: true,
          )
          : _handle(
            request,
            pathToAssetId(_rootPackage, rootDir, request.url.pathSegments),
          );

  Future<shelf.Response> _handle(
    shelf.Request request,
    AssetId assetId, {
    bool fallbackToDirectoryList = false,
  }) async {
    try {
      try {
        if (!await _reader.canRead(assetId)) {
          var reason = await _reader.unreadableReason(assetId);
          switch (reason) {
            case UnreadableReason.failed:
              return shelf.Response.internalServerError(
                body: 'Build failed for $assetId',
              );
            case UnreadableReason.notOutput:
              return shelf.Response.notFound('$assetId was not output');
            case UnreadableReason.notFound:
              if (fallbackToDirectoryList) {
                return shelf.Response.notFound(
                  await _findDirectoryList(assetId),
                );
              }
              return shelf.Response.notFound('Not Found');
            default:
              return shelf.Response.notFound('Not Found');
          }
        }
      } on ArgumentError // ignore: avoid_catching_errors
      catch (_) {
        return shelf.Response.notFound('Not Found');
      }

      var etag = base64.encode((await _reader.digest(assetId)).bytes);
      var contentType = _typeResolver.lookup(assetId.path);
      if (contentType == 'text/x-dart') {
        contentType = '$contentType; charset=utf-8';
      }
      var headers = <String, Object>{
        if (contentType != null) HttpHeaders.contentTypeHeader: contentType,
        HttpHeaders.etagHeader: etag,
        // We always want this revalidated, which requires specifying both
        // max-age=0 and must-revalidate.
        //
        // See spec https://goo.gle/maxage for more info about this header.
        HttpHeaders.cacheControlHeader: 'max-age=0, must-revalidate',
      };

      if (request.headers[HttpHeaders.ifNoneMatchHeader] == etag) {
        // This behavior is still useful for cases where a file is hit
        // without a cache-busting query string.
        return shelf.Response.notModified(headers: headers);
      }
      List<int>? body;
      if (request.method != 'HEAD') {
        body = await _reader.readAsBytes(assetId);
        headers[HttpHeaders.contentLengthHeader] = '${body.length}';
      }
      return shelf.Response.ok(body, headers: headers);
    } catch (e) {
      buildLog.info(
        buildLog.renderThrowable(
          'Error on request ${request.method} ${request.requestedUri}',
          e,
        ),
      );
      rethrow;
    }
  }

  Future<String> _findDirectoryList(AssetId from) async {
    var directoryPath = p.url.dirname(from.path);
    var glob = p.url.join(directoryPath, '*');
    var result =
        await _reader.assetFinder.find(Glob(glob)).map((a) => a.path).toList();
    var message = StringBuffer('Could not find ${from.path}');
    if (result.isEmpty) {
      message.write(' or any files in $directoryPath. ');
    } else {
      message
        ..write('. $directoryPath contains:')
        ..writeAll(result, '\n')
        ..writeln();
    }
    message.write(
      ' See https://github.com/dart-lang/build/blob/master/docs/faq.md'
      '#why-cant-i-see-a-file-i-know-exists',
    );
    return '$message';
  }
}

/// [shelf.Middleware] that logs all requests, inspired by [shelf.logRequests].
shelf.Handler _logRequests(shelf.Handler innerHandler) {
  return (shelf.Request request) async {
    var startTime = DateTime.now();
    var watch = Stopwatch()..start();
    try {
      var response = await innerHandler(request);
      var logFn = response.statusCode >= 500 ? buildLog.warning : buildLog.info;
      var msg = _requestLabel(
        startTime,
        response.statusCode,
        request.requestedUri,
        request.method,
        watch.elapsed,
      );
      logFn(msg);
      return response;
    } catch (error, stackTrace) {
      if (error is shelf.HijackException) rethrow;
      var msg = _requestLabel(
        startTime,
        500,
        request.requestedUri,
        request.method,
        watch.elapsed,
      );
      buildLog.error(buildLog.renderThrowable(msg, error, stackTrace));
      rethrow;
    }
  };
}

String _requestLabel(
  DateTime requestTime,
  int statusCode,
  Uri requestedUri,
  String method,
  Duration elapsedTime,
) {
  return '${requestTime.toIso8601String()} '
      '${buildLog.renderDuration(elapsedTime)} '
      '$method [$statusCode] '
      '${requestedUri.path}${_formatQuery(requestedUri.query)}\r\n';
}

String _formatQuery(String query) {
  return query == '' ? '' : '?$query';
}
