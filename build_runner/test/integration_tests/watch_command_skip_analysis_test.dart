// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Tags(['integration3'])
library;

import 'package:build_runner/src/logging/build_log.dart';
import 'package:test/test.dart';

import '../common/common.dart';

void main() async {
  test('watch command skip analysis', () async {
    final pubspecs = await Pubspecs.load();
    final tester = BuildRunnerTester(pubspecs);

    tester.writeFixturePackage(FixturePackages.resolveBuilder);
    tester.writePackage(
      name: 'root_pkg',
      dependencies: ['build_runner'],
      pathDependencies: ['builder_pkg'],
      files: {
        'lib/a.dart': '''
library a;
import 'b.dart';
int x = 3;
''',
        'lib/b.dart': '''
import 'c.dart';

int y = 4;
''',
        'lib/c.dart': '''
''',
      },
    );

    // Watch and initial build.
    final watch = await tester.start('root_pkg', 'dart run build_runner watch');
    await watch.expect(BuildLog.successPattern);
    expect(tester.read('root_pkg/lib/a.resolved'), 'a');

    // Updating `c.dart` with a change that does not affect its API should
    // cause `c.resolved` to be rebuilt but not `a.resolved` or `b.resolved`.
    tester.write('root_pkg/lib/c.dart', '// new comment');
    var line = await watch.expectAndGetLine(BuildLog.successPattern);
    expect(line, contains('wrote 1 output'));

    // Updating `c.dart` with a change that does affect its API should
    // cause all three to be rebuilt.
    tester.write('root_pkg/lib/c.dart', 'int z = 3;');
    line = await watch.expectAndGetLine(BuildLog.successPattern);
    expect(line, contains('wrote 3 outputs'));

    // Now try a code change that still doesn't affect the API.
    tester.write('root_pkg/lib/c.dart', 'int z = 4;');
    line = await watch.expectAndGetLine(BuildLog.successPattern);
    expect(line, contains('wrote 1 output'));
  });
}
