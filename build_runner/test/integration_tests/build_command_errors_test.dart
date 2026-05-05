// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Tags(['integration1'])
library;

import 'package:test/test.dart';

import '../common/common.dart';

void main() async {
  test('build command errors', () async {
    final pubspecs = await Pubspecs.load();
    final tester = BuildRunnerTester(pubspecs);

    tester.writePackage(
      name: 'builder_pkg',
      dependencies: ['build', 'build_runner'],
      files: {
        'build.yaml': '''
builders:
  test_builder:
    import: 'package:builder_pkg/builder.dart'
    builder_factories: ['testBuilderFactory']
    build_extensions: {'.txt': ['.txt.copy']}
    auto_apply: root_package
    build_to: source
''',
        'lib/builder.dart': '''
import 'dart:io';
import 'package:build/build.dart';

Builder testBuilderFactory(BuilderOptions options) => TestBuilder();

class TestBuilder implements Builder {
  @override
  Map<String, List<String>> get buildExtensions => {'.txt': ['.txt.copy']};

  @override
  Future<void> build(BuildStep buildStep) async {
    log.warning('builder ran');
    log.severe('builder failed');
  }
}
''',
      },
    );
    tester.writePackage(
      name: 'root_pkg',
      dependencies: ['build_runner'],
      pathDependencies: ['builder_pkg'],
      files: {'web/a.txt': 'a'},
    );

    var output = await tester.run(
      'root_pkg',
      'dart run build_runner build --force-jit',
      expectExitCode: 1,
    );
    expect(output, contains('builder ran'));
    expect(output, contains('builder failed'));

    // On rebuild: nothing changed, so the action does not run again.
    // Errors are serialized so the error is reported again; the warning is not.
    output = await tester.run(
      'root_pkg',
      'dart run build_runner build --force-jit',
      expectExitCode: 1,
    );
    expect(output, isNot(contains('builder ran')));
    expect(output, contains('builder failed'));

    // Throwing instead of `log.severe` is equivalent.
    tester.update(
      'builder_pkg/lib/builder.dart',
      (script) => script.replaceAll(
        "log.severe('builder failed');",
        "throw 'builder failed';",
      ),
    );
    output = await tester.run(
      'root_pkg',
      'dart run build_runner build --force-jit',
      expectExitCode: 1,
    );
    expect(output, contains('builder ran'));
    expect(output, contains('builder failed'));
    // Now with stack trace.
    expect(
      output,
      contains('TestBuilder.build (package:builder_pkg/builder.dart'),
    );

    // Now with post process builder errors.
    tester.writePackage(
      name: 'builder_pkg',
      dependencies: ['build', 'build_runner'],
      files: {
        'build.yaml': '''
builders:
  test_builder:
    import: "package:builder_pkg/builder.dart"
    builder_factories: ["testBuilder"]
    build_extensions: {".dart": [".unused"]}
    auto_apply: all_packages
    build_to: cache
    applies_builders:
      - builder_pkg:test_post_process_builder
post_process_builders:
  test_post_process_builder:
    import: "package:builder_pkg/builder.dart"
    builder_factory: "testPostProcessBuilder"
    input_extensions: [".txt"]
    build_to: cache
    defaults:
      options:
        output_extension: ".post"
''',
        'lib/builder.dart': '''
import 'package:build/build.dart';

TestBuilder testBuilder(BuilderOptions options) => TestBuilder();
TestPostProcessBuilder testPostProcessBuilder(BuilderOptions options)
    => TestPostProcessBuilder(options.config['output_extension'] as String);

class TestBuilder implements Builder {
  @override
  Map<String, List<String>> get buildExtensions => {'.dart': ['.unused']};

  @override
  Future<void> build(BuildStep buildStep) async {}
}

class TestPostProcessBuilder implements PostProcessBuilder {
  final String outputExtension;
  TestPostProcessBuilder(this.outputExtension);

  @override
  List<String> get inputExtensions => ['.txt'];

  @override
  Future<void> build(PostProcessBuildStep buildStep) async {
    log.warning('post process builder ran');
    log.severe('post process builder failed');
    await buildStep.writeAsString(
      buildStep.inputId.addExtension(outputExtension),
      'failed output',
    );
  }
}
''',
      },
    );
    tester.writePackage(
      name: 'root_pkg',
      dependencies: ['build_runner'],
      pathDependencies: ['builder_pkg'],
      files: {'web/a.txt': 'a'},
    );

    // Initial build. It should fail because the post process builder logged a
    // severe error.
    output = await tester.run(
      'root_pkg',
      'dart run build_runner build --force-jit',
      expectExitCode: 1,
    );
    expect(output, contains('post process builder ran'));
    expect(output, contains('post process builder failed'));

    // On rebuild: nothing changed, so the action does not run again.
    // Errors are serialized so the error is reported again; the warning is not.
    output = await tester.run(
      'root_pkg',
      'dart run build_runner build --force-jit',
      expectExitCode: 1,
    );
    expect(output, isNot(contains('post process builder ran')));
    expect(output, contains('post process builder failed'));
  });
}
