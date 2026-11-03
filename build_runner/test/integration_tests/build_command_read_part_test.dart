// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Tags(['integration4'])
library;

import 'package:build_runner/src/logging/build_log.dart';
import 'package:test/test.dart';

import '../common/common.dart';

void main() {
  test('build command read part', () async {
    final pubspecs = await Pubspecs.load();
    final tester = BuildRunnerTester(pubspecs);

    tester.writePackage(
      name: 'root_pkg',
      dependencies: ['build', 'build_runner'],
      files: {
        'build.yaml': r'''
builders:
  write_part_builder:
    import: 'tool/builder.dart'
    builder_factories: ['writePartBuilderFactory']
    build_extensions: {'.dart': []}
    auto_apply: root_package
    build_to: source
    adds_to_library: true
    runs_before: ['root_pkg:read_part_builder']
  read_part_builder:
    import: 'tool/builder.dart'
    builder_factories: ['readPartBuilderFactory']
    build_extensions: {'.dart': ['.copy']}
    auto_apply: root_package
    build_to: source
targets:
  $default:
    builders:
      root_pkg:read_part_builder:
        generate_for: ['lib/a.dart']
''',
        'tool/builder.dart': r'''
import 'package:build/build.dart';

Builder writePartBuilderFactory(BuilderOptions options) => WritePartBuilder();
Builder readPartBuilderFactory(BuilderOptions options) => ReadPartBuilder();

class WritePartBuilder implements Builder {
  @override
  Map<String, List<String>> get buildExtensions => {'.dart': []};

  @override
  Future<void> build(BuildStep buildStep) async {
    (await buildStep.librarySourceSink)?.add('// part content');
  }
}

/// Copies the shared part of its input, as written by earlier phases.
class ReadPartBuilder implements Builder {
  @override
  Map<String, List<String>> get buildExtensions => {'.dart': ['.copy']};

  @override
  Future<void> build(BuildStep buildStep) async {
    final partId = AssetId(buildStep.inputId.package, 'lib/_br_/a.part.dart');
    await buildStep.writeAsString(
      buildStep.inputId.changeExtension('.copy'),
      await buildStep.readAsString(partId),
    );
  }
}
''',
        'lib/a.dart': "part '_br_/a.part.dart';\n\nclass A {}\n",
      },
    );

    final output = await tester.run(
      'root_pkg',
      'dart run build_runner build --force-jit',
    );
    expect(output, contains(BuildLog.successPattern));
    expect(
      tester.read('root_pkg/lib/a.copy'),
      contains(
        '// === root_pkg:write_part_builder contribution.\n'
        '// part content\n',
      ),
    );
  });
}
