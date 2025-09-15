// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Tags(['integration3'])
library;

import 'package:build_runner/src/logging/build_log.dart';
import 'package:test/test.dart';

import '../common/common.dart';

void main() async {
  test('watch command invalidation', () async {
    final pubspecs = await Pubspecs.load();
    final tester = BuildRunnerTester(pubspecs);

    tester.writeFixturePackage(FixturePackages.copyBuilder());
    tester.writePackage(
      name: 'root_pkg',
      dependencies: ['build_runner'],
      pathDependencies: ['builder_pkg'],
      files: {'web/a.txt': 'a'},
    );

    // Watch and initial build.
    var watch = await tester.start('root_pkg', 'dart run build_runner watch');
    await watch.expect(BuildLog.successPattern);
    expect(tester.read('root_pkg/web/a.txt.copy'), 'a');

    // Builder change.
    tester.update('builder_pkg/lib/builder.dart', (script) => '$script\n');
    await watch.expect('Terminating builds due to build script update');
    await watch.expect('Compiling the build script');
    await watch.expect('Creating the asset graph');
    await watch.expect(BuildLog.successPattern);
    expect(tester.read('root_pkg/web/a.txt.copy'), 'a');

    // Builder config change.
    tester.write('root_pkg/build.yaml', '# new file, nothing here');
    await watch.expect('Terminating builds due to root_pkg:build.yaml update');
    await watch.expect(BuildLog.successPattern);
    expect(tester.read('root_pkg/web/a.txt.copy'), 'a');

    // Now with --output.
    await watch.kill();
    watch = await tester.start(
      'root_pkg',
      'dart run build_runner watch --output web:build',
    );
    await watch.expect(BuildLog.successPattern);
    expect(tester.read('root_pkg/build/a.txt'), 'a');
    expect(tester.read('root_pkg/build/a.txt.copy'), 'a');

    // Changed inputs and outputs are written to output directory.
    tester.write('root_pkg/lib/a.txt', 'updated');
    await watch.expect(BuildLog.successPattern);
    expect(tester.read('root_pkg/build/a.txt'), 'a');
    expect(tester.read('root_pkg/build/a.txt.copy'), 'a');
  });
}
