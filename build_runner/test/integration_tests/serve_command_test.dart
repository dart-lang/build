// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(davidmorgan): find unused port so this can run in parallel.
@Tags(['integration'])
library;

import 'dart:io';

import 'package:io/io.dart';
import 'package:test/test.dart';

import '../common/common.dart';

void main() async {
  test('serve command', () async {
    final pubspecs = await Pubspecs.load();
    final tester = BuildRunnerTester(pubspecs);

    tester.writePackage(
      name: 'root_pkg',
      dependencies: ['build_runner'],
      files: {},
    );

    final serve = await tester.start('root_pkg', 'dart run build_runner serve');
    await serve.expect(
      'Missing dev dependency on package:build_web_compilers, '
      'which is required to serve Dart compiled to JavaScript.',
    );
    await serve.expect('Found no known web directories to serve');
    await serve.kill();

    // Create some source to serve.
    tester.write('root_pkg/web/a.txt', 'a');

    // Start a server on the same port, serve, check the error.
    final server = await HttpServer.bind('localhost', 8080);
    addTearDown(server.close);
    final output = await tester.run(
      'root_pkg',
      'dart run build_runner serve web:8080',
      expectExitCode: ExitCode.osError.code,
    );
    expect(
      output,
      allOf(
        contains('Error starting server'),
        contains('8080'),
        contains('address is already in use'),
      ),
    );
    await server.close();
  });
}
