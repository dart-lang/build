// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:build/build.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart';

import '../generate/build_result.dart';
import '../generate/watch_impl.dart';

Future<ServeHandler> createServeHandler(WatchImpl watch) async {
  var rootPackage = watch.packageGraph.root.name;
  var assetHandler = new AssetHandler(await watch.reader, rootPackage);
  return new ServeHandler._(watch, assetHandler);
}

class ServeHandler implements BuildState {
  final BuildState _state;
  final AssetHandler _assetHandler;
  BuildResult _lastBuildResult;

  ServeHandler._(this._state, this._assetHandler) {
    _state.buildResults.listen((result) {
      _lastBuildResult = result;
    });
  }

  @override
  Future<BuildResult> get currentBuild => _state.currentBuild;
  @override
  Stream<BuildResult> get buildResults => _state.buildResults;

  Handler handlerFor(String rootDir) {
    if (p.url.split(rootDir).length != 1) {
      throw new ArgumentError.value(
          rootDir, 'rootDir', 'Only top level directories are supported');
    }
    return (Request request) => _handle(request, rootDir);
  }

  FutureOr<Response> _handle(Request request, String rootDir) async {
    await currentBuild;
    if (_lastBuildResult.status == BuildStatus.failure) {
      return new Response(HttpStatus.INTERNAL_SERVER_ERROR,
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

  Future<Response> handle(Request request, String rootDir) {
    var pathSegments = <String>[rootDir];
    pathSegments.addAll(request.url.pathSegments);

    if (request.url.path.endsWith('/') || request.url.path.isEmpty) {
      pathSegments = new List.from(pathSegments)..add('index.html');
    }
    return _handle(request.headers, pathSegments);
  }

  Future<Response> _handle(
      Map<String, String> requestHeaders, List<String> pathSegments) async {
    var packagesIndex = pathSegments.indexOf('packages');
    var assetId = packagesIndex >= 0
        ? new AssetId(pathSegments[packagesIndex + 1],
            p.join('lib', p.joinAll(pathSegments.sublist(packagesIndex + 2))))
        : new AssetId(_rootPackage, p.joinAll(pathSegments));
    try {
      if (!await _reader.canRead(assetId)) {
        return new Response.notFound('Not Found');
      }
    } on ArgumentError catch (_) {
      return new Response.notFound('Not Found');
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
      return new Response.notModified(headers: headers);
    }

    var bytes = await _reader.readAsBytes(assetId);
    headers[HttpHeaders.CONTENT_LENGTH] = '${bytes.length}';
    return new Response.ok(bytes, headers: headers);
  }
}
