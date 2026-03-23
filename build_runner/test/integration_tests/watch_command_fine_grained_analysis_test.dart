// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Tags(['integration3'])
library;

import 'package:build_runner/src/logging/build_log.dart';
import 'package:test/test.dart';

import '../common/common.dart';

void main() async {
  test('watch command', timeout: const Timeout.factor(4), () async {
    final pubspecs = await Pubspecs.load();
    final tester = BuildRunnerTester(pubspecs);

    tester.writeFixturePackage(FixturePackages.analyzingBuilder());
    tester.writePackage(
      name: 'root_pkg',
      dependencies: ['build_runner'],
      pathDependencies: ['builder_pkg'],
      files: {
        'lib/a.dart': '''
import 'b.dart';
class A implements B{}
''',
        'lib/b.dart': '''
class B {}
''',
      },
    );

    // Watch and initial build.
    final watch = await tester.start('root_pkg', 'dart run build_runner watch');
    await watch.expect(BuildLog.successPattern);
    expect(tester.read('root_pkg/lib/a.txt'), '''
A
  Object
  B
''');

    tester.write('root_pkg/lib/b.dart', '''
class B {}

class C {}
''');
    await watch.expect(BuildLog.successPattern);

    fail('');
  });
}
