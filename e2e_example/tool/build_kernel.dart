// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:build_config/build_config.dart';
import 'package:build_web_compilers/build_web_compilers.dart';
import 'package:build_runner/build_runner.dart';
import 'package:build_test/builder.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

Future main() async {
  var builders = [
    apply('e2e_example|test_bootstrap', [(_) => new TestBootstrapBuilder()],
        toRoot(),
        defaultGenerateFor:
            const InputSet(include: const ['test/**_test.dart']),
        hideOutput: true),
    apply(
        'build_compilers|ddc',
        [
          (_) => new ModuleBuilder(),
          (_) => new KernelSummaryBuilder(),
          (_) => new DevCompilerBuilder(useKernel: true),
        ],
        toAllPackages(),
        isOptional: true,
        hideOutput: true),
    apply(
        'build_web_compilers|entrypoint',
        [
          (_) => new WebEntrypointBuilder(WebCompiler.DartDevc, useKernel: true)
        ],
        toRoot(),
        defaultGenerateFor: const InputSet(include: const [
          'web/**.dart',
          'test/**.browser_test.dart',
        ]),
        hideOutput: true)
  ];

  var serveHandler = await watch(
    builders,
    deleteFilesByDefault: true,
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
