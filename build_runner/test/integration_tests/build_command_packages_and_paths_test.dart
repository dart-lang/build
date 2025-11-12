// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Tags(['integration4'])
library;

import 'package:test/test.dart';

import '../common/common.dart';

void main() async {
  test('build command packages and paths', () async {
    final pubspecs = await Pubspecs.load();
    final tester = BuildRunnerTester(pubspecs);

    tester.writeFixturePackage(
      FixturePackages.copyBuilder(buildToCache: true, applyToAllPackages: true),
    );
    tester.writePackage(
      name: 'root_pkg',
      dependencies: ['build_runner'],
      pathDependencies: ['builder_pkg'],
      files: {'lib/a.txt': 'a'},
    );

    // Runs in a subdirectory of the package.
    await tester.run('root_pkg/lib', 'dart run build_runner build');
    expect(tester.readFileTree('root_pkg/.dart_tool/build/generated'), {
      'root_pkg/lib/a.txt.copy': 'a',
    });
  });
}
