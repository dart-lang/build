// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:http_multi_server/http_multi_server.dart';
import 'package:meta/meta.dart';
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

  @visibleForTesting
  static Handler createHandler(
    BuildRunnerDaemonBuilder builder,
    String outputRootPackage,
  ) {
    final cascade = Cascade()
        .add((_) async {
          await builder.building;
          return Response.notFound('');
        })
        .add(
          AssetHandler(
            () async => (await builder.buildSeries.currentBuildResult)
                .buildOutputReader,
            outputRootPackage,
          ).handle,
        );

    return const Pipeline()
        .addMiddleware(_loopbackOnly)
        .addHandler(cascade.handler);
  }

  static Future<AssetServer> run(
    DaemonOptions options,
    BuildRunnerDaemonBuilder builder,
    String outputRootPackage,
  ) async {
    final server = await HttpMultiServer.loopback(0);

    var pipeline = const Pipeline();
    if (options.logRequests) {
      pipeline = pipeline.addMiddleware(
        logRequests(logger: (message, isError) => buildLog.info(message)),
      );
    }

    shelf_io.serveRequests(
      server,
      pipeline.addHandler(createHandler(builder, outputRootPackage)),
    );
    return AssetServer._(server);
  }
}

bool _isLoopback(String host) =>
    host == 'localhost' ||
    (InternetAddress.tryParse(host)?.isLoopback ?? false);

/// Rejects requests that lack a loopback Host header or specify a non-loopback
/// Origin header.
Handler _loopbackOnly(Handler inner) => (request) {
  final hostHeader = request.headers['host'];
  if (hostHeader == null) return Response.forbidden(null);

  final host = Uri.tryParse('http://$hostHeader')?.host ?? '';
  if (!_isLoopback(host)) {
    return Response.forbidden(null);
  }

  final origin = request.headers['origin'];
  if (origin != null) {
    final parsed = Uri.tryParse(origin);
    if (parsed == null || !_isLoopback(parsed.host)) {
      return Response.forbidden(null);
    }
  }

  return inner(request);
};
