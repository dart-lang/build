// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';

import '../generate/options.dart';
import '../generate/watch_impl.dart';

/// The actual [HttpServer] in use.
Future<HttpServer> _futureServer;

/// Public for testing purposes only :(. This file is not directly exported
/// though so it is effectively package private.
Handler blockingHandler;

/// Starts a server which blocks on any ongoing builds.
Future<HttpServer> startServer(WatchImpl watchImpl, BuildOptions options) {
  if (_futureServer != null) {
    throw new StateError('Server already running.');
  }

  try {
    blockingHandler = (Request request) async {
      if (watchImpl.currentBuild != null) await watchImpl.currentBuild;
      return options.requestHandler(request);
    };
    _futureServer = serve(blockingHandler, options.address, options.port);
    return _futureServer;
  } catch (e, s) {
    stderr.writeln('Error setting up server: $e\n\n$s');
    return new Future.value(null);
  }
}

Future stopServer() {
  if (_futureServer == null) {
    throw new StateError('Server not running.');
  }
  return _futureServer.then((server) {
    server.close();
    _futureServer = null;
    blockingHandler = null;
  });
}
