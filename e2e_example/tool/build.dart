// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:build/build.dart';
import 'package:build_compilers/build_compilers.dart';
import 'package:build_runner/build_runner.dart';
import 'package:build_test/builder.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

Future main() async {
  var graph = new PackageGraph.forThisPackage();
  var buildActions = <BuildAction>[
    new BuildAction(new TestBootstrapBuilder(), graph.root.name,
        inputs: ['test/**_test.dart']),
    new BuildAction(new ThrowingBuilder(), graph.root.name),
  ];

  void addBuilderForAll(Builder builder, String inputExtension) {
    for (var packageNode in graph.orderedPackages) {
      buildActions
          .add(new BuildAction(builder, packageNode.name, isOptional: true));
    }
  }

  addBuilderForAll(new ModuleBuilder(), '.dart');
  addBuilderForAll(new UnlinkedSummaryBuilder(), moduleExtension);
  addBuilderForAll(new LinkedSummaryBuilder(), moduleExtension);
  addBuilderForAll(new DevCompilerBuilder(), moduleExtension);

  buildActions.add(new BuildAction(
      new DevCompilerBootstrapBuilder(), graph.root.name,
      inputs: ['web/**.dart', 'test/**.browser_test.dart']));

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

class ThrowingBuilder extends Builder {
  @override
  final buildExtensions = {
    '.fail': ['.fail.message']
  };

  @override
  Future<Null> build(BuildStep buildStep) async {
    throw await buildStep.readAsString(buildStep.inputId);
  }
}
