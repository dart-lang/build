// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_static/shelf_static.dart';

import '../generate/watch_impl.dart';

HttpServer _server;

Future startServer(WatchImpl watchImpl,
    {String directory: '.',
    String address: 'localhost',
    int port: 8000}) async {
  if (_server != null) {
    throw new StateError('Server already running.');
  }

  try {
    var staticHandler = createStaticHandler(directory,
        defaultDocument: 'index.html', listDirectories: true);
    var blockingHandler = (Request request) async {
      if (watchImpl.currentBuild != null) await watchImpl.currentBuild;
      return staticHandler(request);
    };
    _server = await serve(blockingHandler, address, port);
  } catch (e, s) {
    stderr.writeln('Error setting up server: $e\n\n$s');
  }
}

Future stopServer() {
  if (_server == null) {
    throw new StateError('Server not running.');
  }
  return _server.close();
}
