// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Tags(['integration1'])
library;

import 'package:build_runner/src/logging/build_log.dart';
import 'package:test/test.dart';

import '../common/common.dart';

void main() {
  test('build command write part in a workspace', () async {
    final pubspecs = await Pubspecs.load();
    final tester = BuildRunnerTester(pubspecs);

    // Adds to libraries in packages that depend on it, writing its import
    // prefix.
    tester.writePackage(
      name: 'write_part_pkg',
      dependencies: ['build', 'build_runner'],
      files: {
        'build.yaml': r'''
builders:
  write_part_builder:
    import: 'package:write_part_pkg/builder.dart'
    builder_factories: ['writePartBuilderFactory']
    build_extensions: {'.dart': []}
    auto_apply: dependents
    build_to: 'source'
    adds_to_library: true
''',
        'lib/builder.dart': r'''
import 'package:build/build.dart';

Builder writePartBuilderFactory(BuilderOptions options) => WritePartBuilder();

class WritePartBuilder implements Builder {
  @override
  Map<String, List<String>> get buildExtensions => {'.dart': []};

  @override
  Future<void> build(BuildStep buildStep) async {
    final sink = await buildStep.librarySourceSink;
    sink?.add('// prefix ${sink.importPrefix}');
  }
}
''',
      },
    );

    // Adds to libraries only in `other_pkg`, before `write_part_builder`, so
    // in a workspace build it takes phase numbers that a build of `root_pkg`
    // alone does not have.
    tester.writePackage(
      name: 'other_builder_pkg',
      dependencies: ['build', 'build_runner'],
      files: {
        'build.yaml': r'''
builders:
  other_builder:
    import: 'package:other_builder_pkg/builder.dart'
    builder_factories: ['otherBuilderFactory']
    build_extensions: {'.dart': []}
    auto_apply: dependents
    build_to: 'source'
    adds_to_library: true
    runs_before: ['write_part_pkg:write_part_builder']
''',
        'lib/builder.dart': r'''
import 'package:build/build.dart';

Builder otherBuilderFactory(BuilderOptions options) => OtherBuilder();

class OtherBuilder implements Builder {
  @override
  Map<String, List<String>> get buildExtensions => {'.dart': []};

  @override
  Future<void> build(BuildStep buildStep) async {
    (await buildStep.librarySourceSink)?.add('// other');
  }
}
''',
      },
    );

    tester.writePackage(
      name: 'other_pkg',
      dependencies: ['build_runner'],
      pathDependencies: ['other_builder_pkg', 'write_part_pkg'],
      files: {'lib/o.dart': "part '_br_/o.part.dart';\n\nclass O {}\n"},
      inWorkspace: true,
    );
    tester.writePackage(
      name: 'root_pkg',
      dependencies: ['build_runner'],
      pathDependencies: ['other_pkg', 'write_part_pkg'],
      files: {'lib/a.dart': "part '_br_/a.part.dart';\n\nclass A {}\n"},
      inWorkspace: true,
    );
    tester.writeWorkspacePubspec(packages: ['other_pkg', 'root_pkg']);

    const expectedPart = r'''
// dart format off
part of '../a.dart';

// === write_part_pkg:write_part_builder contribution.
// prefix $0

''';

    // Building each package alone. `root_pkg` depends on `other_pkg`, so in
    // a workspace build the phases for `other_pkg` come first.
    await tester.run('other_pkg', 'dart run build_runner build --force-jit');
    var output = await tester.run(
      'root_pkg',
      'dart run build_runner build --force-jit',
    );
    expect(output, contains(BuildLog.successPattern));
    expect(tester.read('root_pkg/lib/_br_/a.part.dart'), expectedPart);

    // Building the workspace gives the same shared part, so it passes
    // `--only-check`.
    output = await tester.run(
      '',
      'dart run build_runner build --force-jit --workspace --only-check',
    );
    expect(output, contains(BuildLog.successPattern));
    expect(tester.read('root_pkg/lib/_br_/a.part.dart'), expectedPart);
  });
}
