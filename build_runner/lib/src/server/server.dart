// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:io';

import 'package:build/build.dart';
import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart';

import '../generate/build_result.dart';
import '../generate/watch_impl.dart';

class BuildHandler implements BuildState {
  final BuildState _state;
  final AssetHandler _assetHandler;

  static Future<BuildHandler> create(WatchImpl watch) async {
    var rootPackage = watch.packageGraph.root.name;
    var assetHandler = new AssetHandler(await watch.reader, rootPackage);
    return new BuildHandler(watch, assetHandler);
  }

  BuildHandler(this._state, this._assetHandler);

  @override
  Future<BuildResult> get currentBuild => _state.currentBuild;
  @override
  Stream<BuildResult> get buildResults => _state.buildResults;

  Future<Response> handle(Request request) async {
    await currentBuild;
    return _assetHandler.handle(request);
  }
}

class AssetHandler {
  final AssetReader _reader;
  final String _rootPackage;

  AssetHandler(this._reader, this._rootPackage);

  Future<Response> handle(Request request) async {
    var pathSegments = request.url.pathSegments;
    var assetId = (pathSegments.first == 'packages')
        ? new AssetId(pathSegments[1], p.joinAll(pathSegments.sublist(2)))
        : new AssetId(_rootPackage, p.joinAll(pathSegments));
    try {
      if (!await _reader.canRead(assetId)) {
        return new Response.notFound('Not Found');
      }
    } on ArgumentError catch (_) {
      return new Response.notFound('Not Found');
    }
    var bytes = await _reader.readAsBytes(assetId);
    var headers = {HttpHeaders.CONTENT_LENGTH: '${bytes.length}'};
    return new Response.ok(bytes, headers: headers);
  }
}
