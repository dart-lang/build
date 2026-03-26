// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Tags(['integration3'])
library;

import 'package:build_runner/src/logging/build_log.dart';
import 'package:test/test.dart';

import '../common/common.dart';

void main() async {
  test('watch command concurrent changes', () async {
    final pubspecs = await Pubspecs.load();
    final tester = BuildRunnerTester(pubspecs);

    tester.writeFixturePackage(FixturePackages.copyBuilder());
    // Builder with a one second delay before read.
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
    auto_apply: 'root_package'
    build_to: 'source'
''',
        'lib/builder.dart': '''
import 'package:build/build.dart';

Builder testBuilderFactory(BuilderOptions options) => TestBuilder();

class TestBuilder implements Builder {
  @override
  Map<String, List<String>> get buildExtensions
      => {'.txt': ['.txt.copy']};

  @override
  Future<void> build(BuildStep buildStep) async {
    await Future.delayed(Duration(seconds: 1));
    buildStep.writeAsString(
        buildStep.inputId.addExtension('.copy'),
        await buildStep.readAsString(buildStep.inputId),
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

    // Files with primary outputs are read at the start of the build. So a
    // delete during the build does not interrupt the build.
    var watch = await tester.start('root_pkg', 'dart run build_runner watch');
    // Wait for the build to start then delete the input.
    await watch.expect('builder_pkg:test_builder');
    tester.delete('root_pkg/lib/a.txt');
    await watch.expect(BuildLog.successPattern);
    expect(tester.read('root_pkg/lib/a.txt.copy'), 'a');
    // Second build was triggered.
    await watch.expect(BuildLog.successPattern);
    expect(tester.read('root_pkg/lib/a.txt.copy'), null);

    // Files that are not primary inputs are not read at the start of the first
    // build. If they are never actually used then deleting them during the
    // build does not interrupt the build, nor does it trigger a new build.
    tester.write('root_pkg/lib/a.txt', 'a');
    tester.write('root_pkg/lib/a.other', 'a');
    // Wait for the build to start then delete the non-primary input.
    await watch.expect('builder_pkg:test_builder');
    tester.delete('root_pkg/lib/a.other');
    await watch.expect(BuildLog.successPattern);
    await watch.expectNoOutput(const Duration(seconds: 1));
    await watch.kill();

    // Change the builder so it also reads a non-primary file.
    tester.write('builder_pkg/lib/builder.dart', '''
import 'package:build/build.dart';

Builder testBuilderFactory(BuilderOptions options) => TestBuilder();

class TestBuilder implements Builder {
  @override
  Map<String, List<String>> get buildExtensions
      => {'.txt': ['.txt.copy']};

  @override
  Future<void> build(BuildStep buildStep) async {
    final id = AssetId('root_pkg', 'lib/a.other');
    final canRead = await buildStep.canRead(id);
    await Future.delayed(Duration(seconds: 1));
    if (canRead) {
      await buildStep.readAsString(id);
    }
    buildStep.writeAsString(
        buildStep.inputId.addExtension('.copy'),
        await buildStep.readAsString(buildStep.inputId),
    );
  }
}
''');

    // The non-primary input is not read on startup, so the build needs
    // to restart to recover.
    tester.write('root_pkg/lib/a.other', 'a');
    watch = await tester.start('root_pkg', 'dart run build_runner watch');
    // Wait for the build to start then delete the non-primary input.
    await watch.expect('builder_pkg:test_builder');
    tester.delete('root_pkg/lib/a.other');
    await watch.expect(
      'root_pkg|lib/a.other was unexpectedly deleted, restarting the build.',
    );
    await watch.expect('Starting build #2.');
    await watch.expect(BuildLog.successPattern);

    // If there was a succesful build using the non-primary input then it's
    // known to be used, and _will_ be read at the start of the build. Then,
    // deleting it during the build will not interrupt the build.
    tester.write('root_pkg/lib/a.other', 'a');
    await watch.expect(BuildLog.successPattern);
    tester.write('root_pkg/lib/a.txt', 'rebuild');
    // Wait for the build to start then delete the non-primary input.
    await watch.expect('builder_pkg:test_builder');
    tester.delete('root_pkg/lib/a.other');
    await watch.expect(BuildLog.successPattern);
    // But it will trigger a follow-on build.
    await watch.expect(BuildLog.successPattern);
  });
}
