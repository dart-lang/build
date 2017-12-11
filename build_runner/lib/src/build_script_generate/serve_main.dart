// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build_runner/build_runner.dart';
import 'package:shelf/shelf_io.dart';

import 'options.dart';

Future serveMain(List<String> args, List<BuilderApplication> builders) async {
  var actions = createBuildActions(new PackageGraph.forThisPackage(), builders);
  var options = new Options.parse(args);
  var handler = await watch(actions, assumeTty: options.assumeTty);
  var server = await serve(handler.handlerFor('web'), 'localhost', 8000);
  await handler.buildResults.drain();
  await server.close();
}
