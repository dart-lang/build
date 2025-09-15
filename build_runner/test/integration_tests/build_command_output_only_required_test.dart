// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Tags(['integration2'])
library;

import 'package:test/test.dart';

import '../common/common.dart';

void main() async {
  test('build command --output writes only required files', () async {
    final pubspecs = await Pubspecs.load();
    final tester = BuildRunnerTester(pubspecs);
    tester.writeFixturePackage(FixturePackages.optionalCopyAndReadBuilders);

    tester.writePackage(
      name: 'root_pkg',
      dependencies: ['build_runner'],
      pathDependencies: ['builder_pkg'],
      files: {'lib/a.txt': 'a', 'lib/b.txt': 'b'},
    );

    // Initial build produces no output as the copy is not required.
    await tester.run('root_pkg', 'dart run build_runner build --output build');
    expect(tester.readFileTree('root_pkg/build/packages/root_pkg'), {
      'a.txt': 'a',
      'b.txt': 'b',
    });

    // Read a copy so that it is now required.
    tester.write('root_pkg/lib/new.read', 'root_pkg|lib/a.txt.copy');
    await tester.run('root_pkg', 'dart run build_runner build --output build');
    expect(tester.readFileTree('root_pkg/build/packages/root_pkg'), {
      'new.read': 'root_pkg|lib/a.txt.copy',
      'a.txt': 'a',
      'a.txt.copy': 'a',
      'b.txt': 'b',
    });

    // Stop requiring the copy and it is no longer output to `build`.
    tester.delete('root_pkg/lib/new.read');
    await tester.run('root_pkg', 'dart run build_runner build --output build');
    expect(tester.readFileTree('root_pkg/build/packages/root_pkg'), {
      'a.txt': 'a',
      'b.txt': 'b',
    });

    // But it is not removed from the source tree.
    expect(tester.readFileTree('root_pkg/lib'), {
      'a.txt': 'a',
      'a.txt.copy': 'a',
      'b.txt': 'b',
    });
  });
}
