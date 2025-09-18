// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Tags(['integration3'])
library;

import 'package:build_runner/src/logging/build_log.dart';
import 'package:test/test.dart';

import '../common/common.dart';

void main() async {
  test('watch command', () async {
    final pubspecs = await Pubspecs.load();
    final tester = BuildRunnerTester(pubspecs);

    tester.writeFixturePackage(FixturePackages.copyBuilder());
    tester.writePackage(
      name: 'root_pkg',
      dependencies: ['build_runner'],
      pathDependencies: ['builder_pkg', 'other_pkg'],
      files: {'web/a.txt': 'a'},
    );
    tester.writePackage(
      name: 'other_pkg',
      dependencies: ['build_runner'],
      pathDependencies: ['builder_pkg'],
      files: {},
    );

    // Watch and initial build.
    var watch = await tester.start('root_pkg', 'dart run build_runner watch');
    await watch.expect(BuildLog.successPattern);
    expect(tester.read('root_pkg/web/a.txt.copy'), 'a');

    // File change.
    tester.write('root_pkg/web/a.txt', 'updated');
    await watch.expect(BuildLog.successPattern);
    expect(tester.read('root_pkg/web/a.txt.copy'), 'updated');

    // File rewrite without change.
    tester.write('root_pkg/web/a.txt', 'updated');
    await watch.expectNoOutput(const Duration(seconds: 1));

    // State on disk is updated so `build` knows to do nothing.
    var output = await tester.run('root_pkg', 'dart run build_runner build');
    expect(output, contains('wrote 0 outputs'));

    // New file.
    tester.write('root_pkg/web/b.txt', 'b');
    await watch.expect(BuildLog.successPattern);
    expect(tester.read('root_pkg/web/b.txt.copy'), 'b');

    // State on disk is updated so `build` knows to do nothing.
    output = await tester.run('root_pkg', 'dart run build_runner build');
    expect(output, contains('wrote 0 outputs'));

    // Deleted file.
    tester.delete('root_pkg/web/b.txt');
    await watch.expect(BuildLog.successPattern);
    expect(tester.read('root_pkg/web/b.txt.copy'), null);

    // Deleted output.
    tester.delete('root_pkg/web/a.txt.copy');
    await watch.expect(BuildLog.successPattern);
    expect(tester.read('root_pkg/web/a.txt.copy'), 'updated');

    // Builder change.
    tester.update('builder_pkg/lib/builder.dart', (script) => '$script\n');
    await watch.expect('Compiling the build script');
    // await watch.expect('Creating the asset graph');
    await watch.expect(BuildLog.successPattern);
    expect(tester.read('root_pkg/web/a.txt.copy'), 'updated');

    // State on disk is updated so `build` knows to do nothing.
    output = await tester.run('root_pkg', 'dart run build_runner build');
    expect(output, contains('wrote 0 outputs'));

    // Builder config change, add a file but it has no effect.
    tester.write('root_pkg/build.yaml', '# new file, nothing here');
    await watch.expectNoOutput(const Duration(seconds: 1));

    // Builder config change that does change options.
    tester.write('root_pkg/build.yaml', r'''
targets:
  $default:
    builders:
      builder_pkg:test_builder:
        options:
          some_option: "any value"
''');
    await watch.expect('wrote 1 output');

    //await watch.expect('Terminating builds due to root_pkg:build.yaml update');
    //await watch.expect(BuildLog.successPattern);
    //expect(tester.read('root_pkg/web/a.txt.copy'), 'updated');

    // Builder config change, update a file but it has no effect.
    tester.update('root_pkg/build.yaml', (yaml) => '$yaml\n');
    await watch.expectNoOutput(const Duration(seconds: 1));

    // Builder config delete that does change options.
    tester.delete('root_pkg/build.yaml');
    await watch.expect('wrote 1 output');

    // Builder config change in dependency but it has no effect.
    tester.write('other_pkg/build.yaml', '# new file, nothing here');
    await watch.expectNoOutput(const Duration(seconds: 1));

    // Builder config change in root overriding dependency but it has no effect.
    tester.write('root_pkg/other_pkg.build.yaml', '# new file, nothing here');
    await watch.expectNoOutput(const Duration(seconds: 1));

    // State on disk is updated so `build` knows to do nothing.
    output = await tester.run('root_pkg', 'dart run build_runner build');
    expect(output, contains('wrote 0 outputs'));

    // File change during build.
    tester.write('root_pkg/web/a.txt', 'a');
    await watch.expect('Building');
    tester.write('root_pkg/web/a.txt', 'updated');
    await watch.expect(BuildLog.successPattern);
    expect(tester.read('root_pkg/web/a.txt.copy'), 'a');
    await watch.expect(BuildLog.successPattern);
    expect(tester.read('root_pkg/web/a.txt.copy'), 'updated');

    // No-op change to `package_config.json` causes a build.
    tester.update(
      'root_pkg/.dart_tool/package_config.json',
      (script) => '$script\n',
    );
    await watch.expect(BuildLog.successPattern);
    await watch.kill();

    // Now with --output.
    tester.write('root_pkg/web/a.txt', 'updated');
    watch = await tester.start(
      'root_pkg',
      'dart run build_runner watch --output web:build',
    );
    await watch.expect(BuildLog.successPattern);
    expect(tester.read('root_pkg/build/a.txt'), 'updated');
    expect(tester.read('root_pkg/build/a.txt.copy'), 'updated');

    // Changed inputs and outputs are written to output directory.
    tester.write('root_pkg/web/a.txt', 'a');
    await watch.expect(BuildLog.successPattern);
    expect(tester.read('root_pkg/build/a.txt'), 'a');
    expect(tester.read('root_pkg/build/a.txt.copy'), 'a');
  });
}
