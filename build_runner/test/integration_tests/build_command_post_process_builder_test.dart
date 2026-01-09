// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Tags(['integration4'])
library;

import 'package:test/test.dart';

import '../common/common.dart';

void main() async {
  test('build command with post process builder', () async {
    final pubspecs = await Pubspecs.load();
    final tester = BuildRunnerTester(pubspecs);

    tester.writePackage(
      name: 'builder_pkg',
      dependencies: ['build', 'build_runner'],
      files: {
        'build.yaml': '''
builders:
  test_builder:
    import: "package:builder_pkg/builder.dart"
    builder_factories: ["testBuilder"]
    build_extensions: {".dart": [".g.dart"]}
    auto_apply: root_package
    build_to: source
    applies_builders:
      - builder_pkg:test_post_process_builder
post_process_builders:
  test_post_process_builder:
    import: "package:builder_pkg/builder.dart"
    builder_factory: "testPostProcessBuilder"
    input_extensions: [".txt"]
    defaults:
      options:
        output_extension: ".post"
      dev_options:
        extra_content: "(default dev)"
      release_options:
        extra_content: "(default release)"
''',
        'lib/builder.dart': '''
import 'package:build/build.dart';

TestBuilder testBuilder(BuilderOptions options)
    => TestBuilder();
TestPostProcessBuilder testPostProcessBuilder(BuilderOptions options)
    => TestPostProcessBuilder(
        options.config['output_extension'] as String,
        options.config['extra_content'] as String);

class TestBuilder implements Builder {
  @override
  Map<String, List<String>> get buildExtensions => {'.dart': ['.g.dart']};

  @override
  Future<void> build(BuildStep buildStep) async {}
}

class TestPostProcessBuilder implements PostProcessBuilder {
  final String outputExtension;
  final String extraContent;
  TestPostProcessBuilder(this.outputExtension, this.extraContent);

  @override
  List<String> get inputExtensions => ['.txt'];

  @override
  Future<void> build(PostProcessBuildStep buildStep) async {
    await buildStep.writeAsString(
        buildStep.inputId.addExtension(outputExtension),
        await buildStep.readInputAsString() + extraContent,
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
      files: {'lib/a.txt': 'a'},
    );

    // Initial build.
    await tester.run('root_pkg', 'dart run build_runner build --output build');
    expect(tester.readFileTree('root_pkg/build/packages/root_pkg'), {
      'a.txt': 'a',
      'a.txt.post': 'a(default dev)',
    });

    // No rebuild if nothing changed.
    var output = await tester.run(
      'root_pkg',
      'dart run build_runner build --output build',
    );
    expect(output, contains('wrote 0 outputs'));

    // Do rebuild if a file changed.
    tester.write('root_pkg/lib/a.txt', 'b');
    output = await tester.run(
      'root_pkg',
      'dart run build_runner build --output build',
    );
    expect(output, contains('wrote 1 output'));
    // Restore the original input.
    tester.write('root_pkg/lib/a.txt', 'a');

    // Release build.
    await tester.run(
      'root_pkg',
      'dart run build_runner build '
          '--output build --release',
    );
    expect(tester.readFileTree('root_pkg/build/packages/root_pkg'), {
      'a.txt': 'a',
      'a.txt.post': 'a(default release)',
    });

    // Configure via `build.yaml`.
    tester.write('root_pkg/build.yaml', r'''
targets:
  $default:
    builders:
      builder_pkg:test_post_process_builder:
        options:
          output_extension: ".other_post"
        dev_options:
          extra_content: "(yaml dev)"
        release_options:
          extra_content: "(yaml release)"
''');
    await tester.run('root_pkg', 'dart run build_runner build --output build');
    expect(tester.readFileTree('root_pkg/build/packages/root_pkg'), {
      'a.txt': 'a',
      'a.txt.other_post': 'a(yaml dev)',
    });

    // Configure with `--define`.
    await tester.run(
      'root_pkg',
      'dart run build_runner build --output build '
          '--define=builder_pkg:test_post_process_builder=output_extension='
          '.third_post',
    );
    expect(tester.readFileTree('root_pkg/build/packages/root_pkg'), {
      'a.txt': 'a',
      'a.txt.third_post': 'a(yaml dev)',
    });

    // Configure with `--define` and `--release`.
    await tester.run(
      'root_pkg',
      'dart run build_runner build --output build '
          '--define=builder_pkg:test_post_process_builder=output_extension='
          '.third_post --release',
    );
    expect(tester.readFileTree('root_pkg/build/packages/root_pkg'), {
      'a.txt': 'a',
      'a.txt.third_post': 'a(yaml release)',
    });
  });
}
