// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Tags(['integration2'])
library;

import 'package:build_runner/src/logging/build_log.dart';
import 'package:test/test.dart';

import '../common/common.dart';

void main() async {
  test('builder changes', () async {
    final pubspecs = await Pubspecs.load();
    final tester = BuildRunnerTester(pubspecs);

    tester.writeFixturePackage(FixturePackages.copyBuilder());
    tester.writePackage(
      name: 'root_pkg',
      dependencies: ['build_runner'],
      pathDependencies: ['builder_pkg'],
      files: {'web/a.txt': 'a'},
    );

    // Start watch mode, wait for initial build.
    final watch = await tester.start(
      'root_pkg',
      'dart run build_runner watch --force-jit',
    );
    await watch.expect(BuildLog.successPattern);

    // Modify builder, then modify it again during the compile of the first
    // modified code.
    tester.update(
      'builder_pkg/lib/builder.dart',
      (script) => script.replaceAll(r"'$extraContent'", "'(v1)'"),
    );
    await watch.expect('Starting build #2 with updated builders.');
    await watch.expect(RegExp(r'1s compiling builders/jit'));
    tester.update(
      'builder_pkg/lib/builder.dart',
      (script) => script.replaceAll("'(v1)'", "'(v2)'"),
    );
    await watch.expect('Starting build #3 with updated builders.');
    await watch.expect(BuildLog.successPattern);
    await watch.kill();

    // Verify that the output is from the latest modified code.
    expect(tester.read('root_pkg/web/a.txt.copy'), 'a(v2)');
  });
}
