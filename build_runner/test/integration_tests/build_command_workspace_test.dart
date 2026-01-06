// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Tags(['integration4'])
library;

import 'package:test/test.dart';

import '../common/common.dart';

void main() async {
  test('build command workspace', () async {
    final pubspecs = await Pubspecs.load();
    final tester = BuildRunnerTester(pubspecs);

    tester.writeFixturePackage(FixturePackages.copyBuilder());
    tester.writePackage(
      name: 'root_pkg',
      dependencies: ['build_runner'],
      pathDependencies: ['builder_pkg'],
      workspaceDependencies: ['dep_pkg'],
      files: {'lib/a.txt': 'a'},
      inWorkspace: true,
    );
    tester.writePackage(
      name: 'dep_pkg',
      files: {'lib/b.txt': 'b'},
      inWorkspace: true,
    );
    tester.writePackage(
      name: 'other_pkg',
      files: {'lib/c.txt': 'c'},
      inWorkspace: true,
    );
    tester.write('pubspec.yaml', '''
name: workspace
environment:
  sdk: ^3.5.0
workspace:
  - root_pkg
  - dep_pkg
  - other_pkg
''');

    await tester.run('root_pkg/lib', 'dart run build_runner build --workspace');
    expect(tester.read('root_pkg/lib/a.txt.copy'), 'a');
    expect(tester.read('dep_pkg/lib/b.txt.copy'), 'b');
    expect(tester.read('other_pkg/lib/c.txt.copy'), 'c');
  });
}
