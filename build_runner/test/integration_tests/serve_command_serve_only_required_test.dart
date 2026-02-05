// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Tags(['integration5'])
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

    var serve = await tester.start(
      'root_pkg',
      'dart run build_runner serve web:0',
    );

    // Initial build produces no output as the copy is not required.
    await serve.expectServingAndBuildSuccess();
    await serve.fetch('a.txt.copy', expectResponseCode: 404);

    // Read a copy so that it is now required.
    tester.write('root_pkg/web/new.read', 'root_pkg|web/a.txt.copy');
    await serve.expect(BuildLog.successPattern);
    expect(await serve.fetchContent('a.txt.copy'), 'a');

    // Stop requiring the copy and it is no longer served.
    tester.delete('root_pkg/web/new.read');
    await serve.expect(BuildLog.successPattern);
    await serve.fetch('a.txt.copy', expectResponseCode: 404);

    // But it is not removed from the source tree.
    expect(tester.readFileTree('root_pkg/web'), {
      'a.txt': 'a',
      'a.txt.copy': 'a',
      'b.txt': 'b',
    });

    // Add a post process builder to regression test for the crash in
    // https://github.com/dart-lang/build/issues/4341.
    await serve.kill();
    tester.writeFixturePackage(
      FixturePackages.postProcessCopyBuilder(
        packageName: 'post_process_builder_pkg',
      ),
    );
    tester.writePackage(
      name: 'root_pkg',
      dependencies: ['build_runner'],
      pathDependencies: ['builder_pkg', 'post_process_builder_pkg'],
      files: {},
    );
    serve = await tester.start('root_pkg', 'dart run build_runner serve web:0');

    await serve.expectServingAndBuildSuccess();
    await serve.fetch('a.txt.copy', expectResponseCode: 404);

    await serve.kill();
  });
}
