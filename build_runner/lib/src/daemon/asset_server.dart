// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:build/build.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

import '../server/path_to_asset_id.dart';
import '../server/server.dart';
import 'daemon_builder.dart';

Future<Response> Function(Request) _outputDigestHandler(
        BuildRunnerDaemonBuilder builder, String rootPackage) =>
    (Request request) async {
      if (request.url.path.endsWith(r'$outputDigests')) {
        var digests = <AssetId, String>{};
        for (var output in builder.outputs) {
          try {
            digests[output] = '${await builder.reader.digest(output)}';
          } on AssetNotFoundException {
            // Ignore assets which can't be found.
          }
        }
        var result = <String, String>{};
        for (var assetId in digests.keys) {
          var path = assetIdToPath(assetId, rootPackage);
          if (path != null) {
            result[path] = digests[assetId];
          }
        }
        return Response.ok(jsonEncode(result));
      }
      return Response.notFound('Not found');
    };

class AssetServer {
  HttpServer _server;

  AssetServer._(this._server);

  int get port => _server.port;

  Future<void> stop() => _server.close(force: true);

  static Future<AssetServer> run(
    BuildRunnerDaemonBuilder builder,
    String rootPackage,
  ) async {
    var server = await HttpServer.bind(InternetAddress.anyIPv6, 0);
    var cascade = Cascade()
        .add((_) async {
          await builder.building;
          return Response.notFound('');
        })
        .add(_outputDigestHandler(builder, rootPackage))
        .add(AssetHandler(builder.reader, rootPackage).handle);
    shelf_io.serveRequests(server, cascade.handler);
    return AssetServer._(server);
  }
}
