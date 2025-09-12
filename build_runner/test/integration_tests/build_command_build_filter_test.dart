// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Tags(['integration'])
library;

import 'package:test/test.dart';

import '../common/common.dart';

void main() async {
  test('build command --build-filter', () async {
    final pubspecs = await Pubspecs.load();
    final tester = BuildRunnerTester(pubspecs);

    tester.writeFixturePackage(
      FixturePackages.copyBuilder(buildToCache: true, applyToAllPackages: true),
    );
    tester.writePackage(
      name: 'root_pkg',
      dependencies: ['build_runner'],
      pathDependencies: ['builder_pkg', 'other_pkg'],
      files: {
        'lib/a.txt': 'a',
        'lib/b.txt': 'b',
        'web/a.txt': 'a',
        'web/b.txt': 'b',
      },
    );
    tester.writePackage(
      name: 'other_pkg',
      files: {'lib/a.txt': 'a', 'lib/b.txt': 'b'},
    );

    await tester.run(
      'root_pkg',
      'dart run build_runner build '
          '--build-filter package:*/a.txt.copy '
          '--build-filter web/a.txt.copy ',
    );
    expect(tester.readFileTree('root_pkg/.dart_tool/build/generated'), {
      'root_pkg/web/a.txt.copy': 'a',
      'root_pkg/lib/a.txt.copy': 'a',
      'other_pkg/lib/a.txt.copy': 'a',
    });
  });
}
