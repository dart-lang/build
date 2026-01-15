// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:build/build.dart';
import 'package:crypto/crypto.dart';
import 'package:glob/glob.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../build/build_result.dart';
import '../../io/build_output_reader.dart';
import '../../logging/build_log.dart';
import '../watch/watcher.dart';
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

class ServeHandler {
  final String outputRootPackage;
  final Watcher _watcher;

  final BuildUpdatesWebSocketHandler _webSocketHandler;

  ServeHandler(this.outputRootPackage, this._watcher)
    : _webSocketHandler = BuildUpdatesWebSocketHandler() {
    _watcher.buildResults
        .listen(_webSocketHandler.emitUpdateMessage)
        .onDone(_webSocketHandler.close);
  }

  Future<BuildResult>? get currentBuildResult => _watcher.currentBuildResult;

  Stream<BuildResult> get buildResults => _watcher.buildResults;

  shelf.Handler handlerFor(
    String rootDir, {
    bool logRequests = false,
    bool liveReload = false,
  }) {
    if (p.url.split(rootDir).length != 1 || rootDir == '.') {
      throw ArgumentError.value(
        rootDir,
        'directory',
        'Only top level directories such as `web` or `test` can be served, got',
      );
    }
    var cascade = shelf.Cascade();
    if (liveReload) {
      cascade = cascade.add(_webSocketHandler.createHandlerByRootDir(rootDir));
    }
    cascade = cascade.add(_blockOnCurrentBuild).add((
      shelf.Request request,
    ) async {
      if (request.url.path == _assetsDigestPath) {
        return _assetsDigestHandler(request, rootDir);
      }
      final assetHandler = AssetHandler(
        () async => (await _watcher.currentBuildResult).buildOutputReader,
        outputRootPackage,
      );
      return assetHandler.handle(request, rootDir: rootDir);
    });
    var pipeline = const shelf.Pipeline();
    if (logRequests) {
      pipeline = pipeline.addMiddleware(_logRequests);
    }
    if (liveReload) {
      pipeline = pipeline.addMiddleware(_injectLiveReloadClientCode);
    }
    return pipeline.addHandler(cascade.handler);
  }

  Future<shelf.Response> _blockOnCurrentBuild(void _) async {
    await currentBuildResult;
    return shelf.Response.notFound('');
  }

  Future<shelf.Response> _assetsDigestHandler(
    shelf.Request request,
    String rootDir,
  ) async {
    final buildResult = await _watcher.currentBuildResult;
    final reader = buildResult.buildOutputReader;
    final assertPathList =
        (jsonDecode(await request.readAsString()) as List).cast<String>();
    final results = <String, String>{};
    for (final path in assertPathList) {
      final assetIds = pathToAssetIds(
        outputRootPackage,
        rootDir,
        p.url.split(path),
      );
      AssetId? assetId;
      for (final id in assetIds) {
        try {
          if (await reader.canRead(id)) {
            assetId = id;
            break;
          }
        } on AssetNotFoundException {
          // Try the next one.
        }
      }

      if (assetId == null) {
        results.remove(path);
      } else {
        final digest = await reader.digest(assetId);
        results[path] = digest.toString();
      }
    }
    return shelf.Response.ok(
      jsonEncode(results),
      headers: {HttpHeaders.contentTypeHeader: 'application/json'},
    );
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

  BuildUpdatesWebSocketHandler([this._handlerFactory = webSocketHandler]);

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
    final reader = buildResult.buildOutputReader;
    final digests = <AssetId, String>{};
    for (final assetId in buildResult.outputs) {
      final digest = await reader.digest(assetId);
      digests[assetId] = digest.toString();
    }
    for (final rootDir in connectionsByRootDir.keys) {
      final resultMap = <String, String?>{};
      for (final assetId in digests.keys) {
        final path = assetIdToPath(assetId, rootDir);
        if (path != null) {
          resultMap[path] = digests[assetId];
        }
      }
      for (final connection in connectionsByRootDir[rootDir]!) {
        connection.sink.add(jsonEncode(resultMap));
      }
    }
  }

  void _handleConnection(
    WebSocketChannel webSocket,
    String? protocol,
    String rootDir,
  ) async {
    final connections = connectionsByRootDir.putIfAbsent(rootDir, () => [])
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
      final originalEtag = response.headers[HttpHeaders.etagHeader];
      if (originalEtag != null) {
        final newEtag = base64.encode(md5.convert(body.codeUnits).bytes);
        final newHeaders = Map.of(response.headers);
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
window.\$dartLoader.forceLoadModule('packages/build_runner/src/commands/serve/$scriptName');
''';

class AssetHandler {
  final Future<BuildOutputReader> Function() _reader;
  final String _outputRootPackage;

  final _typeResolver = MimeTypeResolver();

  AssetHandler(this._reader, this._outputRootPackage);

  Future<shelf.Response> handle(shelf.Request request, {String rootDir = ''}) =>
      (request.url.path.endsWith('/') || request.url.path.isEmpty)
          ? _handle(
            request,
            pathToAssetIds(_outputRootPackage, rootDir, [
              ...request.url.pathSegments.where((p) => p.isNotEmpty),
              'index.html',
            ]),
            fallbackToDirectoryList: true,
          )
          : _handle(
            request,
            pathToAssetIds(
              _outputRootPackage,
              rootDir,
              request.url.pathSegments,
            ),
          );

  Future<shelf.Response> _handle(
    shelf.Request request,
    List<AssetId> assetIds, {
    bool fallbackToDirectoryList = false,
  }) async {
    final reader = await _reader();

    // Use the first of [assetIds] that exists.
    AssetId? assetId;
    for (final id in assetIds) {
      if (await reader.canRead(id)) {
        assetId = id;
        break;
      }
    }
    // Or if none exists, report an error about the first one.
    assetId ??= assetIds.first;

    try {
      try {
        if (!await reader.canRead(assetId)) {
          final reason = await reader.unreadableReason(assetId);
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

      final etag = base64.encode((await reader.digest(assetId)).bytes);
      var contentType = _typeResolver.lookup(assetId.path);
      if (contentType == 'text/x-dart') {
        contentType = '$contentType; charset=utf-8';
      }
      final headers = <String, Object>{
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
        body = await reader.readAsBytes(assetId);
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
    final directoryPath = p.url.dirname(from.path);
    final glob = p.url.join(directoryPath, '*');
    final reader = await _reader();

    final result =
        await reader
            .findAssets(Glob(glob), package: from.package)
            .map((a) => a.path)
            .toList();
    final message = StringBuffer('Could not find ${from.path}');
    if (result.isEmpty) {
      message.write(' or any files in $directoryPath. ');
    } else {
      message
        ..write('. $directoryPath contains:')
        ..writeAll(result, '\n')
        ..writeln();
    }
    return '$message';
  }
}

/// [shelf.Middleware] that logs all requests, inspired by [shelf.logRequests].
shelf.Handler _logRequests(shelf.Handler innerHandler) {
  return (shelf.Request request) async {
    final startTime = DateTime.now();
    final watch = Stopwatch()..start();
    try {
      final response = await innerHandler(request);
      final logFn =
          response.statusCode >= 500 ? buildLog.warning : buildLog.info;
      final msg = _requestLabel(
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
      final msg = _requestLabel(
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
