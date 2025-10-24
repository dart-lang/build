// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Tags(['integration3'])
library;

import 'dart:io';

import 'package:build_runner/src/bootstrap/aot_compiler.dart';
import 'package:build_runner/src/constants.dart';
import 'package:test/test.dart';

import '../common/common.dart';

void main() async {
  test('aot compiler', () async {
    final pubspecs = await Pubspecs.load();
    final tester = BuildRunnerTester(pubspecs);

    tester.writePackage(
      name: 'root_pkg',
      dependencies: ['build_runner'],
      files: {
        'bin/compile.dart': r'''
import 'dart:io';
import 'package:build_runner/src/bootstrap/aot_compiler.dart';
void main() async {
  final compiler = AotCompiler();
  if (compiler.checkFreshness(digestsAreFresh: false).outputIsFresh) {
    stdout.write('fresh\n');
  } else {
    stdout.write('compiling\n');
    final result = await compiler.compile();
    stdout.write('$result\n');
  }
}
''',
      },
    );

    // `stdout.write` is used instead of print to avoid introducing a line
    // ending difference on Windows.

    tester.write('root_pkg/$entrypointScriptPath', r'''
import 'dart:io';
void main() {
  stdout.write('build.dart main\n');
}
''');
    var output = await tester.run('root_pkg', 'dart run root_pkg:compile');
    expect(output, contains('CompileResult(succeeded: true, messages: null)'));
    output = await tester.run('root_pkg', 'dartaotruntime $entrypointAotPath');
    expect(output, contains('build.dart main'));

    // No changes, no rebuild.
    output = await tester.run('root_pkg', 'dart run root_pkg:compile');
    expect(output, contains('fresh'));

    // Rebuilds if output was removed.
    tester.delete('root_pkg/$entrypointAotPath');
    output = await tester.run('root_pkg', 'dart run root_pkg:compile');
    expect(output, contains('succeeded: true'));

    // No changes, no rebuild.
    output = await tester.run('root_pkg', 'dart run root_pkg:compile');
    expect(output, contains('fresh'));

    // Rebuilds if input source was changed.
    tester.write('root_pkg/$entrypointScriptPath', r'''
import 'dart:io';
void main() {
  stdout.write('updated build.dart main\n');
}
''');
    output = await tester.run('root_pkg', 'dart run root_pkg:compile');
    expect(output, contains('succeeded: true'));
    output = await tester.run('root_pkg', 'dartaotruntime $entrypointAotPath');
    expect(output, contains('updated build.dart main'));

    // No changes, no rebuild.
    output = await tester.run('root_pkg', 'dart run root_pkg:compile');
    expect(output, contains('fresh'));

    // Rebuilds if input pubspec was changed.
    tester.write(
      'root_pkg/pubspec.yaml',
      pubspecs.pubspec(
        name: 'root_pkg',
        dependencies: ['build', 'build_runner'],
      ),
    );
    output = await tester.run('root_pkg', 'dart run root_pkg:compile');
    expect(output, contains('succeeded: true'));

    // No changes, no rebuild.
    output = await tester.run('root_pkg', 'dart run root_pkg:compile');
    expect(output, contains('fresh'));

    // Rebuild that introduces an error.
    tester.write('root_pkg/$entrypointScriptPath', r'''
import 'dart:io';
void main() {
  invalid code
}
''');
    output = await tester.run('root_pkg', 'dart run root_pkg:compile');
    expect(output, contains('CompileResult(succeeded: false'));
    expect(output, contains('invalid code'));

    // Same error on retry.
    output = await tester.run('root_pkg', 'dart run root_pkg:compile');
    expect(output, contains('CompileResult(succeeded: false'));
    expect(output, contains('invalid code'));

    // Rebuild that introduces use of mirrors.
    tester.write('root_pkg/$entrypointScriptPath', r'''
import 'dart:mirrors';
void main() {
}
''');
    output = await tester.run('root_pkg', 'dart run root_pkg:compile');
    expect(output, contains('CompileResult(succeeded: false'));
    expect(output, contains('dart:mirrors'));

    // Fix the error.
    tester.write('root_pkg/$entrypointScriptPath', r'''
import 'dart:io';
void main() {
  stdout.write('build.dart main #3\n');
}
''');
    output = await tester.run('root_pkg', 'dart run root_pkg:compile');
    expect(output, contains('succeeded: true'));
    output = await tester.run('root_pkg', 'dartaotruntime $entrypointAotPath');
    expect(output, contains('build.dart main #3'));

    // Depfiles are handled correctly if spaces are in the names.
    tester.write('root_pkg/$entrypointScriptPath', r'''
import 'dart:io';
import 'other file.dart';
void main() {
  stdout.write('build.dart main #3\n');
}
''');
    tester.write('root_pkg/.dart_tool/build/entrypoint/other file.dart', '');
    output = await tester.run('root_pkg', 'dart run root_pkg:compile');
    expect(output, contains('succeeded: true'));

    // No changes, no rebuild.
    output = await tester.run('root_pkg', 'dart run root_pkg:compile');
    expect(output, contains('fresh'));

    // Rebuild on change to imported file.
    tester.write(
      'root_pkg/.dart_tool/build/entrypoint/other file.dart',
      '// updated',
    );
    output = await tester.run('root_pkg', 'dart run root_pkg:compile');
    expect(output, contains('succeeded: true'));

    // Without `dart` on the path.
    tester.write(
      'root_pkg/.dart_tool/build/entrypoint/other file.dart',
      '// updated again',
    );
    final dart = Platform.resolvedExecutable;
    output = await tester.run(
      'root_pkg',
      '$dart run root_pkg:compile',
      environment: {'PATH': ''},
    );
    expect(output, contains('succeeded: true'));
  });
}
