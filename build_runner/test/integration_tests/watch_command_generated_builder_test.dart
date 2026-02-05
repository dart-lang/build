// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Tags(['integration5'])
library;

import 'package:build_runner/src/logging/build_log.dart';
import 'package:test/test.dart';

import '../common/common.dart';

void main() async {
  // Test with a builder that generates some of its own source code. This
  // checks the intersection of handling of two special types of file:
  //
  //  - Source dependencies of the generated build entrypoint. Changes to
  //    these files are handled via a different codepath to other changes
  //    because they can require the build entrypoint to be rebuilt.
  //  - Generated outputs. These are deleted and written during the build.
  test('watch command generated builder', () async {
    final pubspecs = await Pubspecs.load();
    final tester = BuildRunnerTester(pubspecs);

    // The `builder.g.dart` content that the builder writes.
    final partContent = '''
part of 'builder.dart';
''';

    tester.writePackage(
      name: 'builder_pkg',
      dependencies: ['build', 'build_runner'],
      files: {
        'build.yaml': '''
builders:
  test_builder:
    import: 'package:builder_pkg/builder.dart'
    builder_factories: ['testBuilderFactory']
    build_extensions: {'.dart': ['.g.dart']}
    auto_apply: root_package
    build_to: source
''',
        'lib/builder.dart': '''
import 'package:build/build.dart';

part 'builder.g.dart';

Builder testBuilderFactory(BuilderOptions options) => TestBuilder();

class TestBuilder implements Builder {
  @override
  Map<String, List<String>> get buildExtensions => {'.dart': ['.g.dart']};

  @override
  Future<void> build(BuildStep buildStep) async {
    buildStep.writeAsString(
      buildStep.inputId.changeExtension('.g.dart'),
      """$partContent"""
    );
  }
}
''',
        // Start with the correct output.
        'lib/builder.g.dart': partContent,
      },
      inWorkspace: true,
    );
    tester.writePackage(
      name: 'root_pkg',
      workspaceDependencies: ['builder_pkg'],
      files: {},
      inWorkspace: true,
    );
    tester.write('pubspec.yaml', '''
name: workspace
environment:
  sdk: ^3.5.0
workspace: [builder_pkg, root_pkg]
''');

    // The first build runs and writes identical output for the generated file.
    final watch = await tester.start(
      '',
      'dart run build_runner watch --workspace',
    );
    await watch.expect(BuildLog.successPattern);
    expect(tester.read('builder_pkg/lib/builder.g.dart'), partContent);

    // The write of the generated file causes a second build that does nothing
    // because the build has already started before the lack of actual change
    // can be detected in `BuildSeries.run`.
    //
    // Before the fix of https://github.com/dart-lang/build/issues/4348 this
    // would cause a crash due to an "add" event for `builder.g.dart`.
    var line = await watch.expectAndGetLine(BuildLog.successPattern);
    expect(line, contains('wrote 0 outputs'));
    expect(tester.read('builder_pkg/lib/builder.g.dart'), partContent);

    // Update the generated file to something different that does build. The
    // generated build entrypoint is rebuilt then it runs and updates the
    // generated file back to the expected value.
    tester.write('builder_pkg/lib/builder.g.dart', '''
// Different generated output.
part of 'builder.dart';
''');
    await watch.expect('Starting build #3 with updated builders.');
    await watch.expect(BuildLog.successPattern);
    expect(tester.read('builder_pkg/lib/builder.g.dart'), partContent);

    // The generated file content changed so the builders need recompiling.
    // That happens, the build runs and the generated file is written again but
    // this time with the same content.
    await watch.expect('Starting build #4 with updated builders.');
    line = await watch.expectAndGetLine(BuildLog.successPattern);
    expect(line, contains('wrote 1 output'));

    // Write of the generated file to the same content causes another build that
    // does nothing because no input changed.
    await watch.expect('Starting build #5.');
    line = await watch.expectAndGetLine(BuildLog.successPattern);
    expect(line, contains('wrote 0 outputs'));
  });
}
