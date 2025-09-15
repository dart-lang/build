// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Tags(['integration3'])
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
    await serve.expect('Nothing to serve.');
    await serve.kill();

    // Create some source to serve.
    tester.write('root_pkg/web/a.txt', 'a');

    // Start a server serve on the same port, check the error.
    final server = await HttpServer.bind('localhost', 0);
    addTearDown(server.close);
    final output = await tester.run(
      'root_pkg',
      'dart run build_runner serve web:${server.port}',
      expectExitCode: ExitCode.osError.code,
    );
    expect(
      output,
      allOf(
        contains('Failed to start server'),
        contains('${server.port}'),
        contains('address in use'),
      ),
    );
    await server.close();
  });
}
