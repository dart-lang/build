// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Tags(['integration3'])
library;

import 'package:build_runner/src/logging/build_log.dart';
import 'package:test/test.dart';

import '../common/common.dart';

void main() async {
  test('output strategy', () async {
    final pubspecs = await Pubspecs.load();
    final tester = BuildRunnerTester(pubspecs);

    tester.writeFixturePackage(FixturePackages.copyBuilder());
    tester.writePackage(
      name: 'root_pkg',
      dependencies: ['build_runner'],
      pathDependencies: ['builder_pkg'],
      files: {'web/a.txt': 'a', 'web/b.txt': 'b', 'web/c.txt': 'c'},
    );

    // Default output strategy "overwrite" fixes manually modified output.
    await tester.run('root_pkg', 'dart run build_runner build --force-jit');
    expect(tester.read('root_pkg/web/a.txt.copy'), 'a');
    tester.write('root_pkg/web/a.txt.copy', 'User modified a');
    await tester.run('root_pkg', 'dart run build_runner build --force-jit');
    expect(tester.read('root_pkg/web/a.txt.copy'), 'a');

    // With --keep-modified-outputs, manually modified output is kept.
    tester.write('root_pkg/web/a.txt.copy', 'User modified a');
    await tester.run(
      'root_pkg',
      'dart run build_runner build --force-jit --keep-modified-outputs',
    );
    expect(tester.read('root_pkg/web/a.txt.copy'), 'User modified a');

    // With --only-check after an "overwrite" build, passes.
    tester.write('root_pkg/web/a.txt', 'a');
    await tester.run('root_pkg', 'dart run build_runner build --force-jit');
    await tester.run(
      'root_pkg',
      'dart run build_runner build --force-jit --only-check',
    );

    // With --only-check incremental build after modifications to outputs, fails
    // with log describing the differences.
    tester.write('root_pkg/web/a.txt.copy', 'User modified a');
    tester.delete('root_pkg/web/b.txt.copy');
    tester.delete('root_pkg/web/c.txt');
    var output = await tester.run(
      'root_pkg',
      'dart run build_runner build --force-jit --only-check',
      expectExitCode: 1,
    );
    expect(
      output,
      contains('Verify failed due to Incorrect|Missing|Unexpected:'),
    );
    expect(output, contains('I web/a.txt.copy'));
    expect(output, contains('M web/b.txt.copy'));
    expect(output, contains('U web/c.txt.copy'));

    // With --only-check incrementally after fixing manually, passes.
    tester.write('root_pkg/web/a.txt.copy', 'a2');
    tester.write('root_pkg/web/b.txt.copy', 'b');
    tester.write('root_pkg/web/c.txt', 'c');
    await tester.run('root_pkg', 'dart run build_runner build --force-jit');

    // With --only-check on clean build with correct outputs, passes.
    tester.delete('root_pkg/.dart_tool');
    await tester.run(
      'root_pkg',
      'dart run build_runner build --force-jit --only-check',
    );

    // With --only-check clean build with incorrect outputs, fails.
    await tester.run('root_pkg', 'dart run build_runner build --force-jit');
    tester.write('root_pkg/web/a.txt.copy', 'User modified a');
    tester.delete('root_pkg/web/b.txt.copy');
    tester.delete('root_pkg/.dart_tool');
    output = await tester.run(
      'root_pkg',
      'dart run build_runner build --force-jit --only-check',
      expectExitCode: 1,
    );
    expect(
      output,
      contains('Verify failed due to Incorrect|Missing|Unexpected:'),
    );
    expect(output, contains('I web/a.txt.copy'));
    expect(output, contains('M web/b.txt.copy'));

    // watch --only-check stream verification.
    await tester.run('root_pkg', 'dart run build_runner build --force-jit');
    final watch = await tester.start(
      'root_pkg',
      'dart run build_runner watch --force-jit --only-check',
    );
    await watch.expect(BuildLog.successPattern);

    tester.write('root_pkg/web/a.txt.copy', 'User modified a');
    await watch.expect('Verify failed due to Incorrect|Missing|Unexpected:');
    await watch.expect('I web/a.txt.copy');
    await watch.expect(BuildLog.failurePattern);

    tester.write('root_pkg/web/a.txt.copy', 'a');
    await watch.expect(BuildLog.successPattern);
    await watch.kill();
  });

  test('output strategy with part builder', () async {
    final pubspecs = await Pubspecs.load();
    final tester = BuildRunnerTester(pubspecs);

    tester.writePackage(
      name: 'write_part_pkg',
      dependencies: ['build', 'build_runner'],
      files: {
        'build.yaml': '''
builders:
  write_part_builder:
    import: 'package:write_part_pkg/builder.dart'
    builder_factories: ['writePartBuilderFactory']
    build_extensions: {'.dart': []}
    auto_apply: 'root_package'
    build_to: 'cache'
    adds_to_library: true
''',
        'lib/builder.dart': '''
import 'package:build/build.dart';

Builder writePartBuilderFactory(BuilderOptions options) => WritePartBuilder();

class WritePartBuilder implements Builder {
  @override
  Map<String, List<String>> get buildExtensions => {'.dart': []};

  @override
  Future<void> build(BuildStep buildStep) async {
    (await buildStep.librarySourceSink)?.add('// part content');
  }
}
''',
      },
    );

    tester.writePackage(
      name: 'root_pkg',
      dependencies: ['build_runner'],
      pathDependencies: ['write_part_pkg'],
      files: {'lib/a.dart': 'class A {}'},
    );

    await tester.run('root_pkg', 'dart run build_runner build --force-jit');
    expect(
      tester.read('root_pkg/lib/_br_/a.dart'),
      contains('// part content'),
    );

    // Default output strategy "overwrite" fixes manually modified output.
    tester.write('root_pkg/lib/_br_/a.dart', '// User modified part');
    await tester.run('root_pkg', 'dart run build_runner build --force-jit');
    expect(
      tester.read('root_pkg/lib/_br_/a.dart'),
      contains('// part content'),
    );

    // With --keep-modified-outputs, manually modified output is kept.
    tester.write('root_pkg/lib/_br_/a.dart', '// User modified part');
    await tester.run(
      'root_pkg',
      'dart run build_runner build --force-jit --keep-modified-outputs',
    );
    expect(tester.read('root_pkg/lib/_br_/a.dart'), '// User modified part');

    // With --only-check after an "overwrite" build, passes.
    await tester.run('root_pkg', 'dart run build_runner build --force-jit');
    await tester.run(
      'root_pkg',
      'dart run build_runner build --force-jit --only-check',
    );
  });
}
