// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build_runner/src/logging/build_log.dart';
import 'package:test/test.dart';

import '../common/common.dart';

void main() async {
  test('zero-output builders run and track dependencies', () async {
    final pubspecs = await Pubspecs.load();
    final tester = BuildRunnerTester(pubspecs);

    tester.writeFixturePackage(FixturePackages.copyBuilder());

    // Define a builder package that outputs NOTHING to standard files.
    // Crucially, we set is_optional: false to make it a required, eager builder.
    // Since it has zero file outputs, an optional/lazy builder would never be demanded!
    tester.writePackage(
      name: 'zero_output_builder_pkg',
      dependencies: ['build', 'build_runner'],
      files: {
        'build.yaml': '''
builders:
  zero_output_builder:
    import: 'package:zero_output_builder_pkg/builder.dart'
    builder_factories: ['zeroOutputBuilderFactory']
    build_extensions: {'.txt': []} # Declares empty file outputs
    auto_apply: 'root_package'
    build_to: 'cache'
    is_optional: false # Force this builder to be required/eager
''',
        'lib/builder.dart': '''
import 'package:build/build.dart';

Builder zeroOutputBuilderFactory(BuilderOptions options) => ZeroOutputBuilder();

class ZeroOutputBuilder implements Builder {
  @override
  Map<String, List<String>> get buildExtensions => {'.txt': []};

  @override
  Future<void> build(BuildStep buildStep) async {
    // Reads secondary files to record input dependencies!
    final otherId = AssetId(buildStep.inputId.package, 'lib/dep.other');
    if (await buildStep.canRead(otherId)) {
      await buildStep.readAsString(otherId);
    }
    // Use log.warning so it is printed to stdout without needing --verbose
    log.warning('ZeroOutputBuilder ran on \${buildStep.inputId.path}');
  }
}
''',
      },
    );

    // Set up root package with simple inputs
    tester.writePackage(
      name: 'root_pkg',
      dependencies: ['build_runner'],
      pathDependencies: ['zero_output_builder_pkg'],
      files: {
        'lib/a.txt': 'primary content',
        'lib/dep.other': 'dependency content',
      },
    );

    // 1. Initial build. The zero-output builder SHOULD execute eagerly.
    var output = await tester.run(
      'root_pkg',
      'dart run build_runner build --force-jit',
    );
    expect(output, contains(BuildLog.successPattern));
    expect(output, contains('ZeroOutputBuilder ran on lib/a.txt'));

    // 2. Immediate rerun without changes. The builder SHOULD BE CACHED/SKIPPED.
    output = await tester.run(
      'root_pkg',
      'dart run build_runner build --force-jit',
    );
    expect(output, contains(BuildLog.successPattern));
    expect(
      output,
      isNot(contains('ZeroOutputBuilder ran on lib/a.txt')),
    ); // Cached!

    // 3. Modify the secondary input. The builder SHOULD INVALIDATE and RERUN!
    tester.write('root_pkg/lib/dep.other', 'modified dependency content');
    output = await tester.run(
      'root_pkg',
      'dart run build_runner build --force-jit',
    );
    expect(output, contains(BuildLog.successPattern));
    expect(output, contains('ZeroOutputBuilder ran on lib/a.txt')); // Rerun!
  });
}
