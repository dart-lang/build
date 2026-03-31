// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Tags(['integration4'])
library;

import 'package:build_runner/src/logging/build_log.dart';
import 'package:test/test.dart';

import '../common/common.dart';

void main() async {
  test('build command write batching', () async {
    final pubspecs = await Pubspecs.load();
    final tester = BuildRunnerTester(pubspecs);

    tester.writeFixturePackage(
      FixturePackages.copyBuilder(delayAtBuildStart: true),
    );
    tester.writePackage(
      name: 'root_pkg',
      dependencies: ['build_runner'],
      pathDependencies: ['builder_pkg'],
      files: {
        'web/a.txt': 'a',
        // Start with a pre-existing output but no asset graph, it will be
        // noticed during build plan creation and marked for deletion.
        'web/a.txt.copy': 'old',
        'web/b.txt': 'b',
      },
    );

    // The delete should be deferred until the new output is ready.
    final build = await tester.start('root_pkg', 'dart run build_runner build');
    await build.expect('builder_pkg:test_builder');
    expect(tester.read('root_pkg/web/a.txt.copy'), 'old');
    await build.expect(BuildLog.successPattern);
    expect(tester.read('root_pkg/web/a.txt.copy'), 'a');

    // Don't write identical files.
    final stat1 = tester.stat('root_pkg/web/a.txt.copy');
    tester.delete('root_pkg/.dart_tool/build/asset_graph.json');
    await tester.run('root_pkg', 'dart run build_runner build');
    final stat2 = tester.stat('root_pkg/web/a.txt.copy');
    // The file should not have been rewritten. Confirm that `modified` is
    // unchanged. The delay in the builder means it would change reliably
    // if the file was rewritten.
    expect(stat1.modified, stat2.modified);
  });
}
