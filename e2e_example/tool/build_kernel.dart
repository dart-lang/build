// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:build_compilers/build_compilers.dart';
import 'package:build_runner/build_runner.dart';
import 'package:build_test/builder.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

Future main() async {
  var graph = new PackageGraph.forThisPackage();
  var builders = [
    applyToRoot(new TestBootstrapBuilder(), inputs: ['test/**_test.dart']),
    apply(
        'build_compilers',
        'ddc',
        [
          (_) => new ModuleBuilder(),
          (_) => new KernelSummaryBuilder(),
          (_) => new DevCompilerBuilder(useKernel: true),
        ],
        toAllPackages(),
        isOptional: true),
    applyToRoot(new DevCompilerBootstrapBuilder(useKernel: true), inputs: [
      'web/**.dart',
      'test/**.browser_test.dart',
    ])
  ];
  var buildActions = createBuildActions(graph, builders);

  var serveHandler = await watch(
    buildActions,
    deleteFilesByDefault: true,
    writeToCache: true,
  );

  var server =
      await shelf_io.serve(serveHandler.handlerFor('web'), 'localhost', 8080);
  var testServer =
      await shelf_io.serve(serveHandler.handlerFor('test'), 'localhost', 8081);

  await serveHandler.currentBuild;
  stderr.writeln('Serving `web` at http://localhost:8080/');
  stderr.writeln('Serving `test` at http://localhost:8081/');

  await serveHandler.buildResults.drain();
  await server.close();
  await testServer.close();
}
