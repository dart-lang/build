// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Tags(['integration'])
library;

import 'package:test/test.dart';

import '../common/common.dart';

void main() async {
  test('build command --define', () async {
    final pubspecs = await Pubspecs.load();
    final tester = BuildRunnerTester(pubspecs);

    tester.writePackage(
      name: 'builder_pkg',
      dependencies: ['build', 'build_runner'],
      files: {
        'build.yaml': r'''
builders:
  test_builder:
    import: 'package:builder_pkg/builder.dart'
    builder_factories: ['testBuilderFactory']
    build_extensions: {'.txt': ['.txt.copy']}
    auto_apply: root_package
    build_to: source
''',
        'lib/builder.dart': '''
import 'package:build/build.dart';

Builder testBuilderFactory(BuilderOptions options) =>
    TestBuilder(AssetId.parse(options.config['copy_from'] as String));

class TestBuilder implements Builder {
  final AssetId copyFrom;

  TestBuilder(this.copyFrom);

  @override
  Map<String, List<String>> get buildExtensions => {'.txt': ['.txt.copy']};

  @override
  Future<void> build(BuildStep buildStep) async {
    buildStep.writeAsString(
        buildStep.inputId.addExtension('.copy'),
        await buildStep.readAsString(copyFrom),
    );
  }
}''',
      },
    );
    tester.writePackage(
      name: 'root_pkg',
      dependencies: ['build_runner'],
      pathDependencies: ['builder_pkg'],
      files: {
        'build.yaml': r'''
targets:
  $default:
    builders:
      builder_pkg:test_builder:
        options:
          copy_from: root_pkg|web/b.txt
''',
        'web/a.txt': 'a',
        'web/b.txt': 'b',
      },
    );

    // Config in `build.yaml` is the default.
    await tester.run('root_pkg', 'dart run build_runner build');
    expect(tester.read('root_pkg/web/a.txt.copy'), 'b');

    // Override it with `--define`.
    await tester.run(
      'root_pkg',
      'dart run build_runner build '
          '--define=builder_pkg:test_builder=copy_from=root_pkg|web/a.txt',
    );
    expect(tester.read('root_pkg/web/a.txt.copy'), 'a');
  });
}
