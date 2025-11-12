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
      pathDependencies: ['builder_pkg', 'other_pkg'],
      files: {'lib/a.txt': 'a'},
    );
    tester.writePackage(name: 'other_pkg', files: {'lib/b.txt': 'b'});

    // Runs in a subdirectory of the package.
    await tester.run('root_pkg/lib', 'dart run build_runner build');
    expect(tester.readFileTree('root_pkg/.dart_tool/build/generated'), {
      'root_pkg/lib/a.txt.copy': 'a',
      'other_pkg/lib/b.txt.copy': 'b',
    });

    // Remove dep on `other_package`, no longer generated.
    tester.writePackage(
      name: 'root_pkg',
      dependencies: ['build_runner'],
      pathDependencies: ['builder_pkg'],
      files: {'lib/a.txt': 'a'},
    );
    _deletePubspecs(tester);
    await tester.run('root_pkg/lib', 'dart run build_runner build');
    expect(tester.readFileTree('root_pkg/.dart_tool/build/generated'), {
      'root_pkg/lib/a.txt.copy': 'a',
    });

    // Change to a workspace, still no dep onto `other_pkg`.
    tester.writePackage(
      name: 'root_pkg',
      dependencies: ['build_runner'],
      pathDependencies: ['builder_pkg'],
      files: {'lib/a.txt': 'a'},
      inWorkspace: true,
    );
    tester.writePackage(
      name: 'other_pkg',
      files: {'lib/b.txt': 'b'},
      inWorkspace: true,
    );
    tester.write('pubspec.yaml', '''
name: workspace
environment:
  sdk: ^3.5.0
workspace:
  - root_pkg
  - other_pkg
''');

    // Files still not generated for `other_pkg` as it's not a dep.
    _deletePubspecs(tester);
    await tester.run('root_pkg/lib', 'dart run build_runner build');
    expect(tester.readFileTree('root_pkg/.dart_tool/build/generated'), {
      'root_pkg/lib/a.txt.copy': 'a',
    });

    // Add dep onto `other_pkg`.
    tester.writePackage(
      name: 'root_pkg',
      dependencies: ['build_runner'],
      pathDependencies: ['builder_pkg'],
      workspaceDependencies: ['other_pkg'],
      files: {'lib/a.txt': 'a'},
      inWorkspace: true,
    );

    // Files generated for `other_pkg` now it's a dep.
    _deletePubspecs(tester);
    await tester.run('root_pkg/lib', 'dart run build_runner build');
    expect(tester.readFileTree('root_pkg/.dart_tool/build/generated'), {
      'root_pkg/lib/a.txt.copy': 'a',
      'other_pkg/lib/b.txt.copy': 'b',
    });
  });
}

// Work around "dart run" issue https://github.com/dart-lang/sdk/issues/61950.
void _deletePubspecs(BuildRunnerTester tester) {
  if (tester.read('pubspec.lock') != null) tester.delete('pubspec.lock');
  if (tester.read('root_pkg/pubspec.lock') != null) {
    tester.delete('root_pkg/pubspec.lock');
  }
}
