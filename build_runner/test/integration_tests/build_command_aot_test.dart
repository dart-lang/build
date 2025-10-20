// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Tags(['integration2'])
library;

import 'package:test/test.dart';

import '../common/common.dart';

void main() async {
  test('build command AOT', () async {
    final pubspecs = await Pubspecs.load();
    final tester = BuildRunnerTester(pubspecs);

    tester.writeFixturePackage(FixturePackages.copyBuilder());
    tester.writePackage(
      name: 'root_pkg',
      dependencies: ['build_runner'],
      pathDependencies: ['builder_pkg'],
      files: {'web/a.txt': 'a'},
    );

    // First build.
    await tester.run('root_pkg', 'dart run build_runner build --force-aot');
    expect(tester.read('root_pkg/web/a.txt.copy'), 'a');

    // With no changes, no rebuild.
    var output = await tester.run(
      'root_pkg',
      'dart run build_runner build --force-aot',
    );
    expect(output, contains('wrote 0 outputs'));

    // Change the build script, rebuilds.
    tester.update('builder_pkg/lib/builder.dart', (script) => '$script\n');
    output = await tester.run(
      'root_pkg',
      'dart run build_runner build --force-aot',
    );
    expect(output, contains('wrote 1 output'));
  });
}
