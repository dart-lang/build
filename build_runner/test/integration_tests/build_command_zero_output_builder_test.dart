// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Tags(['integration4'])
library;

import 'package:build_runner/src/logging/build_log.dart';
import 'package:test/test.dart';

import '../common/common.dart';

void main() async {
  test('build command with zero output builder', () async {
    final pubspecs = await Pubspecs.load();
    final tester = BuildRunnerTester(pubspecs);

    tester.writePackage(
      name: 'builder_pkg',
      dependencies: ['build', 'build_runner'],
      files: {
        'build.yaml': '''
builders:
  zero_output_builder:
    import: 'package:builder_pkg/builder.dart'
    builder_factories: ['zeroOutputBuilderFactory']
    build_extensions: {'.txt': []} # Declares no outputs.
    auto_apply: 'root_package'
    build_to: 'cache'
    is_optional: false # Required to run.
''',
        'lib/builder.dart': '''
import 'package:build/build.dart';

Builder zeroOutputBuilderFactory(BuilderOptions options) => ZeroOutputBuilder();

class ZeroOutputBuilder implements Builder {
  @override
  Map<String, List<String>> get buildExtensions => {'.txt': []};

  @override
  Future<void> build(BuildStep buildStep) async {
    // Create an input dependency, notify that the builder ran.
    final otherId = AssetId(buildStep.inputId.package, 'lib/dep.other');
    await buildStep.canRead(otherId);
    log.warning('ZeroOutputBuilder ran on \${buildStep.inputId.path}');
  }
}
''',
      },
    );

    tester.writePackage(
      name: 'root_pkg',
      dependencies: ['build_runner'],
      pathDependencies: ['builder_pkg'],
      files: {
        'lib/a.txt': 'primary content',
        'lib/dep.other': 'dependency content',
      },
    );

    // Runs despite having no outputs.
    var output = await tester.run(
      'root_pkg',
      'dart run build_runner build --force-jit',
    );
    expect(output, contains(BuildLog.successPattern));
    expect(output, contains('ZeroOutputBuilder ran on lib/a.txt'));

    // Does not rerun if nothing changed.
    output = await tester.run(
      'root_pkg',
      'dart run build_runner build --force-jit',
    );
    expect(output, contains(BuildLog.successPattern));
    expect(output, isNot(contains('ZeroOutputBuilder ran on lib/a.txt')));

    // Runs if something changes.
    tester.write('root_pkg/lib/dep.other', 'modified dependency content');
    output = await tester.run(
      'root_pkg',
      'dart run build_runner build --force-jit',
    );
    expect(output, contains(BuildLog.successPattern));
    expect(output, contains('ZeroOutputBuilder ran on lib/a.txt')); // Rerun!

    // Now with a mix of zero-output and non-zero-output extensions.
    tester.writePackage(
      name: 'builder_pkg',
      dependencies: ['build', 'build_runner'],
      files: {
        'build.yaml': '''
builders:
  mixed_builder:
    import: 'package:builder_pkg/builder.dart'
    builder_factories: ['mixedBuilderFactory']
    build_extensions: {'.txt': [], '.dart': ['.g.dart']}
    auto_apply: 'root_package'
    build_to: 'cache'
    is_optional: false
''',
        'lib/builder.dart': '''
import 'package:build/build.dart';

Builder mixedBuilderFactory(BuilderOptions options) => MixedBuilder();

class MixedBuilder implements Builder {
  @override
  Map<String, List<String>> get buildExtensions => {'.txt': [], '.dart': ['.g.dart']};

  @override
  Future<void> build(BuildStep buildStep) async {
    log.warning('MixedBuilder ran on \${buildStep.inputId.path}');
    if (buildStep.inputId.path.endsWith('.dart')) {
      await buildStep.writeAsString(
        buildStep.inputId.changeExtension('.g.dart'), '',
      );
    }
  }
}
''',
      },
    );

    tester.writePackage(
      name: 'root_pkg',
      dependencies: ['build_runner'],
      pathDependencies: ['builder_pkg'],
      files: {'lib/a.txt': 'primary content', 'lib/b.dart': 'class B {}'},
    );

    output = await tester.run(
      'root_pkg',
      'dart run build_runner build --force-jit',
    );
    expect(output, contains(BuildLog.successPattern));
    expect(output, contains('MixedBuilder ran on lib/a.txt'));
    expect(output, contains('MixedBuilder ran on lib/b.dart'));
    expect(
      tester.read('root_pkg/.dart_tool/build/generated/root_pkg/lib/b.g.dart'),
      isNotNull,
    );

    // Does not rerun if nothing changed.
    output = await tester.run(
      'root_pkg',
      'dart run build_runner build --force-jit',
    );
    expect(output, contains(BuildLog.successPattern));
    expect(output, isNot(contains('MixedBuilder ran on lib/a.txt')));
    expect(output, isNot(contains('MixedBuilder ran on lib/b.dart')));
  });
}
