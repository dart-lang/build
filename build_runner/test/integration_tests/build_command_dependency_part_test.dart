// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Tags(['integration1'])
library;

import 'package:build_runner/src/logging/build_log.dart';
import 'package:test/test.dart';

import '../common/common.dart';

void main() {
  test('build command with a shared part in a dependency', () async {
    final pubspecs = await Pubspecs.load();
    final tester = BuildRunnerTester(pubspecs);

    // A dependency with a shared part written by its own build and checked
    // in, as a published package would have.
    tester.writePackage(
      name: 'dep_pkg',
      files: {
        'lib/d.dart': "part '_br_/d.part.dart';\n",
        'lib/_br_/d.part.dart': "part of '../d.dart';\n\nclass D {}\n",
      },
    );

    tester.writePackage(
      name: 'resolve_pkg',
      dependencies: ['build', 'build_runner'],
      files: {
        'build.yaml': r'''
builders:
  resolve_builder:
    import: 'package:resolve_pkg/builder.dart'
    builder_factories: ['resolveBuilderFactory']
    build_extensions: {'.dart': ['.resolved.txt']}
    auto_apply: dependents
    build_to: 'source'
''',
        'lib/builder.dart': r'''
import 'package:build/build.dart';

Builder resolveBuilderFactory(BuilderOptions options) => ResolveBuilder();

class ResolveBuilder implements Builder {
  @override
  Map<String, List<String>> get buildExtensions => {'.dart': ['.resolved.txt']};

  @override
  Future<void> build(BuildStep buildStep) async {
    final library = await buildStep.inputLibrary;
    await buildStep.writeAsString(
      buildStep.inputId.changeExtension('.resolved.txt'),
      library.topLevelVariables.map((v) => v.type.getDisplayString()).join(),
    );
  }
}
''',
      },
    );

    tester.writePackage(
      name: 'root_pkg',
      dependencies: ['build_runner'],
      pathDependencies: ['dep_pkg', 'resolve_pkg'],
      files: {
        'lib/a.dart': "import 'package:dep_pkg/d.dart';\n\nfinal d = D();\n",
      },
    );

    // The dependency's shared part is visible to the analyzer.
    var output = await tester.run(
      'root_pkg',
      'dart run build_runner build --force-jit',
    );
    expect(output, contains(BuildLog.successPattern));
    expect(tester.read('root_pkg/lib/a.resolved.txt'), 'D');

    // An incremental build leaves the dependency's shared part alone.
    tester.write(
      'root_pkg/lib/a.dart',
      "import 'package:dep_pkg/d.dart';\n\nfinal d2 = D();\n",
    );
    output = await tester.run(
      'root_pkg',
      'dart run build_runner build --force-jit',
    );
    expect(output, contains(BuildLog.successPattern));
    expect(tester.read('root_pkg/lib/a.resolved.txt'), 'D');
    expect(
      tester.read('dep_pkg/lib/_br_/d.part.dart'),
      "part of '../d.dart';\n\nclass D {}\n",
    );

    // A shared part that appears in the dependency between builds, as after
    // a dependency upgrade, is also a source.
    tester.write('dep_pkg/lib/e.dart', "part '_br_/e.part.dart';\n");
    tester.write(
      'dep_pkg/lib/_br_/e.part.dart',
      "part of '../e.dart';\n\nclass E {}\n",
    );
    tester.write(
      'root_pkg/lib/a.dart',
      "import 'package:dep_pkg/e.dart';\n\nfinal e = E();\n",
    );
    output = await tester.run(
      'root_pkg',
      'dart run build_runner build --force-jit',
    );
    expect(output, contains(BuildLog.successPattern));
    expect(tester.read('root_pkg/lib/a.resolved.txt'), 'E');
    expect(
      tester.read('dep_pkg/lib/_br_/e.part.dart'),
      "part of '../e.dart';\n\nclass E {}\n",
    );
  });
}
