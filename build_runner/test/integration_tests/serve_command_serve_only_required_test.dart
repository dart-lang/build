// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Tags(['integration3'])
library;

import 'package:build_runner/src/logging/build_log.dart';
import 'package:test/test.dart';

import '../common/common.dart';

void main() async {
  test('serve command serves only required files', () async {
    final pubspecs = await Pubspecs.load();
    final tester = BuildRunnerTester(pubspecs);

    tester.writeFixturePackage(FixturePackages.optionalCopyAndReadBuilders);
    tester.writePackage(
      name: 'root_pkg',
      dependencies: ['build_runner'],
      pathDependencies: ['builder_pkg'],
      files: {'web/a.txt': 'a', 'web/b.txt': 'b'},
    );

    final serve = await tester.start(
      'root_pkg',
      'dart run build_runner serve web:0',
    );

    // Initial build produces no output as the copy is not required.
    await serve.expectServing();
    await serve.expect(BuildLog.successPattern);
    await serve.expect404('a.txt.copy');

    // Read a copy so that it is now required.
    tester.write('root_pkg/web/new.read', 'root_pkg|web/a.txt.copy');
    await serve.expect(BuildLog.successPattern);
    await serve.expectContent('a.txt.copy', 'a');

    // Stop requiring the copy and it is no longer served.
    tester.delete('root_pkg/web/new.read');
    await serve.expect(BuildLog.successPattern);
    await serve.expect404('a.txt.copy');

    // But it is not removed from the source tree.
    expect(tester.readFileTree('root_pkg/web'), {
      'a.txt': 'a',
      'a.txt.copy': 'a',
      'b.txt': 'b',
    });

    await serve.kill();
  });
}
