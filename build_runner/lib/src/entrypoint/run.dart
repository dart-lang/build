// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build_runner/build_runner.dart';
import 'package:shelf/shelf_io.dart';

import 'options.dart';

/// A common entrypoint to parse command line arguments and build or serve with
/// [builders].
Future run(List<String> args, List<BuilderApplication> builders) async {
  var options = new Options.parse(args);
  // TODO - remove `delteFileByDefault` once we resolve handling conflicts
  var handler = await watch(builders,
      deleteFilesByDefault: true, assumeTty: options.assumeTty);
  var server = await serve(handler.handlerFor('web'), 'localhost', 8000);
  await handler.buildResults.drain();
  await server.close();
}
