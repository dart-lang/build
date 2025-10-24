// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Tags(['integration2'])
library;

import 'package:build_runner/src/constants.dart' as constants;
import 'package:test/test.dart';

import '../common/common.dart';

void main() async {
  test('build command invalidation', () async {
    final pubspecs = await Pubspecs.load();
    final tester = BuildRunnerTester(pubspecs);

    tester.writeFixturePackage(FixturePackages.copyBuilder());
    tester.writePackage(
      name: 'root_pkg',
      dependencies: ['build_runner'],
      pathDependencies: ['builder_pkg'],
      files: {'web/a.txt': 'a'},
    );

    // Fake generated output to check that stale generated output is deleted.
    final fakeGeneratedOutput =
        'root_pkg/.dart_tool/build/generated/fake_output';

    // First build.
    var output = await tester.run('root_pkg', 'dart run build_runner build');
    expect(output, contains('build_runner/jit'));
    expect(tester.read('root_pkg/web/a.txt.copy'), 'a');

    // With no changes, no rebuild.
    output = await tester.run('root_pkg', 'dart run build_runner build');
    expect(output, contains('wrote 0 outputs'));

    // Change the build script, rebuilds.
    tester.update('builder_pkg/lib/builder.dart', (script) => '$script\n');
    tester.write(fakeGeneratedOutput, '');
    output = await tester.run('root_pkg', 'dart run build_runner build');
    expect(output, contains('wrote 1 output'));
    expect(tester.read(fakeGeneratedOutput), null);

    // Change the build script to output with a different extension. The old
    // output file should be deleted and the new one created.
    tester.update(
      'builder_pkg/lib/builder.dart',
      (script) => script.replaceAll('.copy', '.copy2'),
    );
    await tester.run('root_pkg', 'dart run build_runner build');
    expect(tester.read('root_pkg/web/a.txt.copy'), null);
    expect(tester.read('root_pkg/web/a.txt.copy2'), 'a');

    // Asset graph version mismatch.
    final assetGraphPath = 'root_pkg/${constants.assetGraphPath}';
    tester.update(
      assetGraphPath,
      (json) => json.replaceAll('"version":', '"version":1'),
    );
    tester.write(fakeGeneratedOutput, '');
    output = await tester.run('root_pkg', 'dart run build_runner build');
    expect(output, contains('wrote 1 output'));
    expect(tester.read(fakeGeneratedOutput), null);

    // Move `build_runner` into the test workspace, rebuilds because
    // locations changed.
    tester.copyPackage('build_runner');
    tester.writePackage(
      name: 'root_pkg',
      pathDependencies: ['builder_pkg', 'build_runner'],
      files: {'web/a.txt': 'a'},
    );
    output = await tester.run('root_pkg', 'dart run build_runner build');
    expect(output, contains('wrote 1 output'));

    // No change, no rebuild.
    output = await tester.run('root_pkg', 'dart run build_runner build');
    expect(output, contains('wrote 0 outputs'));

    // Change `build_runner` source, rebuilds.
    tester.update(
      'build_runner/lib/src/build_runner.dart',
      (script) => '$script\n',
    );
    output = await tester.run('root_pkg', 'dart run build_runner build');
    expect(output, contains('wrote 1 output'));
  });
}
