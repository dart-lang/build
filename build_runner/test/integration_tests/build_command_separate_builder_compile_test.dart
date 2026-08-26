// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Tags(['integration2'])
library;

import 'package:test/test.dart';

import '../common/common.dart';

void main() async {
  test('build command --separate-builder-compile', () async {
    final pubspecs = await Pubspecs.load();
    final tester = BuildRunnerTester(pubspecs);

    tester.writeFixturePackage(FixturePackages.copyBuilder());
    tester.writePackage(
      name: 'root_pkg',
      dependencies: ['build_runner'],
      pathDependencies: ['builder_pkg'],
      files: {
        'web/a.txt': 'a',
        'lib/broken.dart': 'THIS IS NOT VALID DART CODE;;; syntax error {{{',
      },
    );

    // First build using --separate-builder-compile.
    var output = await tester.run(
      'root_pkg',
      'dart run build_runner build --separate-builder-compile',
    );
    expect(output, contains('wrote 1 output'));
    expect(tester.read('root_pkg/web/a.txt.copy'), 'a');

    // With no changes, no rebuild (proves depfile freshness check works).
    output = await tester.run(
      'root_pkg',
      'dart run build_runner build --separate-builder-compile',
    );
    expect(output, contains('wrote 0 outputs'));

    // Change the builder script, rebuilds.
    tester.update('builder_pkg/lib/builder.dart', (script) => '$script\n');
    output = await tester.run(
      'root_pkg',
      'dart run build_runner build --separate-builder-compile',
    );
    expect(output, contains('wrote 1 output'));
  });
}
