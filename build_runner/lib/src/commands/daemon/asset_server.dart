// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:http_multi_server/http_multi_server.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

import '../../logging/build_log.dart';
import '../daemon_options.dart';
import '../serve/server.dart';
import 'daemon_builder.dart';

class AssetServer {
  final HttpServer _server;

  AssetServer._(this._server);

  int get port => _server.port;

  Future<void> stop() => _server.close(force: true);

  static Future<AssetServer> run(
    DaemonOptions options,
    BuildRunnerDaemonBuilder builder,
    String rootPackage,
  ) async {
    final server = await HttpMultiServer.loopback(0);
    final cascade = Cascade()
        .add((_) async {
          await builder.building;
          return Response.notFound('');
        })
        .add((request) => _handle(builder, rootPackage, request));

    var pipeline = const Pipeline();
    if (options.logRequests) {
      pipeline = pipeline.addMiddleware(
        logRequests(logger: (message, isError) => buildLog.info(message)),
      );
    }

    shelf_io.serveRequests(server, pipeline.addHandler(cascade.handler));
    return AssetServer._(server);
  }

  static Future<Response> _handle(
    BuildRunnerDaemonBuilder builder,
    String rootPackage,
    Request request,
  ) async {
    final reader = builder.reader;
    if (reader == null) return Response.notFound('');
    final handler = AssetHandler(reader, rootPackage);
    return handler.handle(request);
  }
}
