// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:build_runner/src/server/server.dart';
import 'package:build_runner_core/build_runner_core.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

class AssetServer {
  HttpServer _server;

  AssetServer._(this._server);

  int get port => _server.port;

  Future<void> stop() => _server.close(force: true);

  static Future<AssetServer> run(
      FinalizedReader reader, String rootPackage) async {
    var server = await HttpServer.bind(InternetAddress.anyIPv6, 0);
    shelf_io.serveRequests(server, _handler(reader, rootPackage));
    return AssetServer._(server);
  }

  static Handler _handler(FinalizedReader reader, String rootPackage) {
    var cascade = Cascade().add((request) {
      return AssetHandler(reader, rootPackage).handle(request);
    });
    var pipeline = Pipeline();
    return pipeline.addHandler(cascade.handler);
  }
}
