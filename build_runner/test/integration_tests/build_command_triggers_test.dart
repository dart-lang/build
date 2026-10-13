// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Tags(['integration4'])
library;

import 'package:build_runner/src/logging/build_log.dart';
import 'package:test/test.dart';

import '../common/common.dart';

void main() {
  test('build command triggers', () async {
    final tester = BuildRunnerTester(await Pubspecs.load());

    tester.writePackage(
      name: 'pkg',
      dependencies: ['build', 'build_runner'],
      files: {
        'build.yaml': '''
builders:
  early_triggered_builder:
    import: 'package:pkg/builder.dart'
    builder_factories: ['earlyBuilderFactory']
    build_extensions: {'.dart': ['.early.txt']}
    auto_apply: 'root_package'
    build_to: 'cache'
    runs_before: ['pkg:part_builder']
  part_builder:
    import: 'package:pkg/builder.dart'
    builder_factories: ['writeTriggeringPartBuilderFactory']
    build_extensions: {'.dart': ['.g.dart']}
    auto_apply: 'root_package'
    build_to: 'cache'
    runs_before: ['pkg:late_triggered_builder']
  late_triggered_builder:
    import: 'package:pkg/builder.dart'
    builder_factories: ['lateBuilderFactory']
    build_extensions: {'.dart': ['.late.txt']}
    auto_apply: 'root_package'
    build_to: 'cache'

targets:
  \$default:
    builders:
      pkg:early_triggered_builder:
        options: {run_only_if_triggered: true}
      pkg:late_triggered_builder:
        options: {run_only_if_triggered: true}

triggers:
  pkg:early_triggered_builder:
    - annotation someAnnotation
  pkg:late_triggered_builder:
    - annotation someAnnotation
''',
        'lib/builder.dart': '''
import 'package:build/build.dart';

Builder earlyBuilderFactory(_) => WriteIfTriggeredBuilder('.early.txt');
Builder writeTriggeringPartBuilderFactory(_) => WriteTriggeringPartBuilder();
Builder lateBuilderFactory(_) => WriteIfTriggeredBuilder('.late.txt');

class WriteTriggeringPartBuilder implements Builder {
  @override Map<String, List<String>> get buildExtensions
      => {'.dart': ['.g.dart']};
  @override Future<void> build(BuildStep b) async {
    await b.writeAsString(
      b.inputId.changeExtension('.g.dart'),
      "part of 'a.dart';\\n@someAnnotation\\nclass B {}");
  }
}

class WriteIfTriggeredBuilder implements Builder {
  final String extension;
  WriteIfTriggeredBuilder(this.extension);
  @override Map<String, List<String>> get buildExtensions =>
      {'.dart': [extension]};
  @override Future<void> build(BuildStep b) async {
    await b.writeAsString(b.inputId.changeExtension(extension), 'triggered');
  }
}
''',
        'lib/a.dart': '''
part 'a.g.dart';
class A {}
const someAnnotation = null;
''',
      },
    );

    final output = await tester.run('pkg', 'dart run build_runner build');
    expect(output, contains(BuildLog.successPattern));

    // early_triggered_builder didn't fire, the part with the trigger in it
    // was not generated yet.
    expect(
      tester.read('pkg/.dart_tool/build/generated/pkg/lib/a.early.txt'),
      isNull,
    );
    // late_triggered_builder did fire due to the generated part.
    expect(
      tester.read('pkg/.dart_tool/build/generated/pkg/lib/a.late.txt'),
      contains('triggered'),
    );
  });
}
