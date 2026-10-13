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
    var output = await tester.run(
      'root_pkg',
      'dart run build_runner build --force-jit',
    );
    expect(output, contains('build_runner/jit'));
    expect(tester.read('root_pkg/web/a.txt.copy'), 'a');

    // With no changes, no rebuild.
    output = await tester.run(
      'root_pkg',
      'dart run build_runner build --force-jit',
    );
    expect(output, contains('wrote 0 outputs'));

    // Change the build script, rebuilds.
    tester.update('builder_pkg/lib/builder.dart', (script) => '$script\n');
    tester.write(fakeGeneratedOutput, '');
    output = await tester.run(
      'root_pkg',
      'dart run build_runner build --force-jit',
    );
    expect(output, contains('wrote 1 output'));
    expect(tester.read(fakeGeneratedOutput), null);

    // Change the build script to output with a different extension. The old
    // output file should be deleted and the new one created.
    tester.update(
      'builder_pkg/lib/builder.dart',
      (script) => script.replaceAll('.copy', '.copy2'),
    );
    await tester.run('root_pkg', 'dart run build_runner build --force-jit');
    expect(tester.read('root_pkg/web/a.txt.copy'), null);
    expect(tester.read('root_pkg/web/a.txt.copy2'), 'a');

    // Asset graph version mismatch.
    final assetGraphJsonPath = 'root_pkg/${constants.assetGraphJsonPath}';
    tester.update(
      assetGraphJsonPath,
      (json) => json.replaceAll('"version":', '"version":1'),
    );
    tester.write(fakeGeneratedOutput, '');
    output = await tester.run(
      'root_pkg',
      'dart run build_runner build --force-jit',
    );
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
    tester.writePackage(
      name: 'builder_pkg',
      dependencies: ['build'],
      pathDependencies: ['build_runner'],
      files: {},
    );
    output = await tester.run(
      'root_pkg',
      'dart run build_runner build --force-jit',
    );
    expect(output, contains('wrote 1 output'));

    // No change, no rebuild.
    output = await tester.run(
      'root_pkg',
      'dart run build_runner build --force-jit',
    );
    expect(output, contains('wrote 0 outputs'));

    // Change `build_runner` source, rebuilds.
    tester.update(
      'build_runner/lib/src/build_runner.dart',
      (script) => '$script\n',
    );
    output = await tester.run(
      'root_pkg',
      'dart run build_runner build --force-jit',
    );
    expect(output, contains('wrote 1 output'));

    // Stale output is deleted on incremental build.
    tester.delete('root_pkg/web/a.txt');
    await tester.run('root_pkg', 'dart run build_runner build --force-jit');
    expect(tester.read('root_pkg/web/a.txt.copy2'), null);

    // Conflicting logical ID exists at both package path and in artifact tree.
    tester.writeFixturePackage(
      FixturePackages.copyBuilder(
        buildToCache: true,
        outputExtension: '.artifact',
      ),
    );
    tester.writePackage(
      name: 'root_pkg',
      dependencies: ['build_runner'],
      pathDependencies: ['builder_pkg'],
      files: {'web/a.txt': 'a'},
    );

    // Initial build creates output in the artifact tree.
    await tester.run('root_pkg', 'dart run build_runner build --force-jit');
    final artifactFile =
        'root_pkg/.dart_tool/build/generated/root_pkg/web/a.txt.artifact';
    expect(tester.read(artifactFile), 'a');

    // Create a source file with the exact same logical ID.
    tester.write('root_pkg/web/a.txt.artifact', 'source content');

    // Next build recognizes the new source file and handles the conflict:
    // the conflicting source file is deleted and output remains in the
    // artifact tree.
    await tester.run('root_pkg', 'dart run build_runner build --force-jit');
    expect(tester.read('root_pkg/web/a.txt.artifact'), null);
    expect(tester.read(artifactFile), 'a');

    // Conflicts in the artifact tree deleted when builder outputs to package
    // path.
    tester.writeFixturePackage(
      FixturePackages.copyBuilder(buildToCache: false),
    );
    tester.writePackage(
      name: 'root_pkg',
      dependencies: ['build_runner'],
      pathDependencies: ['builder_pkg'],
      files: {
        'web/a.txt': 'a',
        'web/a.txt.copy': 'package path conflict',
        '.dart_tool/build/generated/root_pkg/web/a.txt.copy':
            'artifact tree conflict',
      },
    );
    // Both locations conflict, builder writes package path: artifact tree is
    // deleted.
    await tester.run('root_pkg', 'dart run build_runner build --force-jit');
    expect(tester.read('root_pkg/web/a.txt.copy'), 'a');
    expect(
      tester.read(
        'root_pkg/.dart_tool/build/generated/root_pkg/web/a.txt.copy',
      ),
      null,
    );

    // Previous package path actual output plus new artifact tree conflict:
    // artifact tree is deleted.
    tester.write(
      'root_pkg/.dart_tool/build/generated/root_pkg/web/a.txt.copy',
      'new artifact tree conflict',
    );
    output = await tester.run(
      'root_pkg',
      'dart run build_runner build --force-jit',
    );
    // The conflicting artifact tree file was deleted and the existing package
    // path output is still valid, so there is no rerun.
    expect(output, contains('wrote 0 outputs'));
    expect(
      tester.read(
        'root_pkg/.dart_tool/build/generated/root_pkg/web/a.txt.copy',
      ),
      null,
    );
    expect(tester.read('root_pkg/web/a.txt.copy'), 'a');
  });
}
