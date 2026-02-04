// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Tags(['integration2'])
library;

import 'package:io/io.dart';
import 'package:test/test.dart';

import '../common/common.dart';

void main() async {
  test('build command --output', () async {
    final pubspecs = await Pubspecs.load();
    final tester = BuildRunnerTester(pubspecs);

    tester.writeFixturePackage(FixturePackages.copyBuilder());
    tester.writePackage(
      name: 'root_pkg',
      dependencies: ['build_runner'],
      pathDependencies: ['builder_pkg'],
      files: {'web/a.txt': 'a', 'web/b.txt': 'b'},
    );

    // The --output option creates a merged output directory.
    await tester.run('root_pkg', 'dart run build_runner build --output build');
    expect(tester.read('root_pkg/build/web/a.txt.copy'), 'a');
    expect(tester.read('root_pkg/build/web/b.txt.copy'), 'b');

    // No rebuild if nothing changed.
    var output = await tester.run(
      'root_pkg',
      'dart run build_runner build --output build',
    );
    expect(output, contains('wrote 0 outputs'));
    // Output is copied the same.
    expect(tester.read('root_pkg/build/web/a.txt.copy'), 'a');
    expect(tester.read('root_pkg/build/web/b.txt.copy'), 'b');

    // The --output option filters to --build-filter.
    await tester.run(
      'root_pkg',
      'dart run build_runner build --output build --build-filter web/b.txt.copy',
    );
    expect(tester.read('root_pkg/build/web/a.txt.copy'), null);
    expect(tester.read('root_pkg/build/web/b.txt.copy'), 'b');

    // The --output option accepts a root.
    await tester.run(
      'root_pkg',
      'dart run build_runner build --output web:build',
    );
    expect(tester.read('root_pkg/build/a.txt.copy'), 'a');
    expect(tester.read('root_pkg/build/b.txt.copy'), 'b');

    // The --output option can be passed multiple times.
    await tester.run(
      'root_pkg',
      'dart run build_runner build --output build1 --output build2',
    );
    expect(tester.read('root_pkg/build1/web/a.txt.copy'), 'a');
    expect(tester.read('root_pkg/build1/web/b.txt.copy'), 'b');
    expect(tester.read('root_pkg/build2/web/a.txt.copy'), 'a');
    expect(tester.read('root_pkg/build2/web/b.txt.copy'), 'b');

    // Duplicate --output options are an error.
    output = await tester.run(
      'root_pkg',
      'dart run build_runner build --output web:build --output test:build',
      expectExitCode: ExitCode.usage.code,
    );
    expect(
      output,
      contains(
        'Invalid argument (--output): Duplicate output directories are not '
        'allowed, got: "web:build test:build"',
      ),
    );

    // Can only specify top level directories to build.
    output = await tester.run(
      'root_pkg',
      'dart run build_runner build --output lib/something:build',
      expectExitCode: ExitCode.usage.code,
    );
    expect(
      output,
      contains(
        'Invalid argument (--output): Input root can not be nested: '
        '"lib/something:build"',
      ),
    );

    // Correct output with specified folder and --symlink.
    await tester.run(
      'root_pkg',
      'dart run build_runner build --output web:build_web --symlink',
    );
    expect(tester.read('root_pkg/build_web/a.txt.copy'), 'a');
    expect(tester.read('root_pkg/build_web/b.txt.copy'), 'b');

    // The --output option refuses to overwrite an existing directory if it
    // does not contain the expected manifest file.
    tester.delete('root_pkg/build/.build.manifest');
    output = await tester.run(
      'root_pkg',
      'dart run build_runner build --output build',
      expectExitCode: ExitCode.cantCreate.code,
    );
    expect(
      output,
      contains(
        'Choose a different directory or delete the contents of that '
        'directory.',
      ),
    );
  });
}
