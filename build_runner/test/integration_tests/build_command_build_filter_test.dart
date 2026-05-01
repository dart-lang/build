// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Tags(['integration1'])
library;

import 'package:test/test.dart';

import '../common/common.dart';

void main() async {
  test('build command --build-filter', () async {
    final pubspecs = await Pubspecs.load();
    final tester = BuildRunnerTester(pubspecs);

    final testFiles = {
      'lib/a.txt': 'a',
      'lib/b.txt': 'b',
      'web/a.txt': 'a',
      'web/b.txt': 'b',
    };

    // Without `--workspace`.
    tester.writeFixturePackage(
      FixturePackages.copyBuilder(buildToCache: true, applyToAllPackages: true),
    );
    tester.writePackage(
      name: 'root_pkg',
      dependencies: ['build_runner'],
      pathDependencies: ['builder_pkg', 'other_pkg'],
      files: testFiles,
    );
    tester.writePackage(name: 'other_pkg', files: testFiles);

    // Paths.
    await tester.run(
      'root_pkg',
      'dart run build_runner build --force-jit '
          '--build-filter */a*',
    );
    expect(tester.readFileTree('root_pkg/.dart_tool/build/generated'), {
      'root_pkg/lib/a.txt.copy': 'a',
      'root_pkg/web/a.txt.copy': 'a',
    });
    tester.delete('root_pkg/.dart_tool/build/generated');

    // `package` scheme.
    await tester.run(
      'root_pkg',
      'dart run build_runner build --force-jit '
          '--build-filter package:*/a*',
    );
    expect(tester.readFileTree('root_pkg/.dart_tool/build/generated'), {
      'root_pkg/lib/a.txt.copy': 'a',
      'other_pkg/lib/a.txt.copy': 'a',
    });
    tester.delete('root_pkg/.dart_tool/build/generated');

    // `asset` scheme.
    await tester.run(
      'root_pkg',
      'dart run build_runner build --force-jit '
          '--build-filter asset:*/*/a*',
    );
    expect(tester.readFileTree('root_pkg/.dart_tool/build/generated'), {
      'root_pkg/web/a.txt.copy': 'a',
      'root_pkg/lib/a.txt.copy': 'a',
      'other_pkg/lib/a.txt.copy': 'a',
      // `other_pkg` `web` is not built because only public outputs of
      // dependency packages are built.
    });
    tester.delete('root_pkg/.dart_tool/build/generated');

    // With `--workspace`.
    tester.writePackage(
      name: 'root_pkg',
      dependencies: ['build_runner', 'other_pkg'],
      pathDependencies: ['builder_pkg'],
      files: testFiles,
      inWorkspace: true,
    );
    tester.writePackage(
      name: 'other_pkg',
      path: 'packages/other_pkg',
      files: testFiles,
      inWorkspace: true,
    );
    tester.writeWorkspacePubspec(packages: ['root_pkg', 'packages/other_pkg']);
    // Apply builder to the workspace too.
    tester.update('pubspec.yaml', (content) {
      return '''
$content
dependencies:
  builder_pkg: 
    path: builder_pkg
''';
    });
    // Put files in the workspace too.
    tester.write('lib/a.txt', 'a');
    tester.write('lib/b.txt', 'a');
    tester.write('web/a.txt', 'a');
    tester.write('web/b.txt', 'a');

    // Paths.
    await tester.run(
      'root_pkg',
      'dart run build_runner build --force-jit --workspace '
          '--build-filter web/a*',
    );
    expect(tester.readFileTree('.dart_tool/build/generated'), {
      'root_pkg/web/a.txt.copy': 'a',
    });
    tester.delete('.dart_tool/build/generated');
    await tester.run(
      'packages/other_pkg',
      'dart run build_runner build --force-jit --workspace '
          '--build-filter web/a*',
    );
    expect(tester.readFileTree('.dart_tool/build/generated'), {
      'other_pkg/web/a.txt.copy': 'a',
    });
    tester.delete('.dart_tool/build/generated');
    await tester.run(
      '',
      'dart run build_runner build --force-jit --workspace '
          '--build-filter web/a*',
    );
    expect(tester.readFileTree('.dart_tool/build/generated'), {
      'workspace/web/a.txt.copy': 'a',
    });
    tester.delete('.dart_tool/build/generated');

    // `package` scheme.
    await tester.run(
      'root_pkg',
      'dart run build_runner build --force-jit --workspace '
          '--build-filter package:*/a*',
    );
    expect(tester.readFileTree('.dart_tool/build/generated'), {
      'root_pkg/lib/a.txt.copy': 'a',
      'other_pkg/lib/a.txt.copy': 'a',
      'workspace/lib/a.txt.copy': 'a',
    });
    tester.delete('.dart_tool/build/generated');

    // `asset` scheme.
    await tester.run(
      'root_pkg',
      'dart run build_runner build --force-jit --workspace '
          '--build-filter asset:*/*/a*',
    );
    expect(tester.readFileTree('.dart_tool/build/generated'), {
      'root_pkg/web/a.txt.copy': 'a',
      'root_pkg/lib/a.txt.copy': 'a',
      'other_pkg/web/a.txt.copy': 'a',
      'other_pkg/lib/a.txt.copy': 'a',
      'workspace/web/a.txt.copy': 'a',
      'workspace/lib/a.txt.copy': 'a',
    });
    tester.delete('.dart_tool/build/generated');
  });
}
