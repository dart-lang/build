// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Timeout(Duration(minutes: 5))
library;

import 'dart:io';
import 'dart:isolate';

import 'package:test/test.dart';

/// Runs `bin/_contract_weaver.dart` in [workingDirectory] with [args].
Future<ProcessResult> _runWeaver(
  String workingDirectory,
  List<String> args,
) async {
  final library = Isolate.resolvePackageUriSync(
    Uri.parse('package:_contract_weaver/contract_weaver.dart'),
  )!;
  final bin = library.resolve('../bin/_contract_weaver.dart').toFilePath();
  final packageConfig = Isolate.packageConfigSync!.toFilePath();
  return Process.run(Platform.resolvedExecutable, [
    '--packages=$packageConfig',
    bin,
    ...args,
  ], workingDirectory: workingDirectory);
}

void main() {
  late Directory tempDir;
  late Directory packageDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('contract_weaver_cli_');
    packageDir = Directory('${tempDir.path}/standalone');

    void write(String path, String content) {
      File('${packageDir.path}/$path')
        ..createSync(recursive: true)
        ..writeAsStringSync(content);
    }

    write('pubspec.yaml', '''
name: standalone
environment:
  sdk: ^3.11.0
dev_dependencies:
  test: any
''');
    write('lib/src/contracts.dart', '''
class Requires {
  final String clause;
  const Requires(this.clause);
}
''');
    write('lib/standalone.dart', '''
import 'src/contracts.dart';

@Requires('x > 0')
int half(int x) => x ~/ 2;
''');
    // Passes only when the precondition is woven in: unwoven, `half(-1)`
    // returns 0.
    write('test/half_test.dart', '''
import 'package:standalone/standalone.dart';
import 'package:test/test.dart';

void main() {
  test('half', () => expect(half(4), 2));
  test('precondition', () {
    expect(
      () => half(-1),
      throwsA(
        predicate((e) => e.toString().contains('Precondition failed: x > 0')),
      ),
    );
  });
}
''');
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  test('weaves and tests a standalone package', () async {
    File('${packageDir.path}/lib/data.txt').writeAsStringSync('data');
    final result = await _runWeaver(packageDir.path, [
      '--stage-dir=${tempDir.path}/stage',
    ]);
    expect(
      result.exitCode,
      0,
      reason: 'stdout: ${result.stdout}\nstderr: ${result.stderr}',
    );
    // Both libraries are transformed: the annotated one, and the one declaring
    // the annotations, which gets the runtime support classes. Other files are
    // linked.
    expect(
      result.stdout,
      contains('Staged standalone/lib: 2 transformed, 1 symlinked.'),
    );
    expect(
      File('${tempDir.path}/stage/lib/data.txt').readAsStringSync(),
      'data',
    );
    expect(
      File('${packageDir.path}/pubspec.lock').existsSync(),
      isFalse,
      reason: 'Resolving the woven copy must not write to the original.',
    );
  });

  test('tests a package without lib', () async {
    Directory('${packageDir.path}/lib').deleteSync(recursive: true);
    File('${packageDir.path}/test/half_test.dart').writeAsStringSync('''
import 'package:test/test.dart';

void main() {
  test('trivial', () => expect(1, 1));
}
''');
    final result = await _runWeaver(packageDir.path, [
      '--stage-dir=${tempDir.path}/stage',
    ]);
    expect(
      result.exitCode,
      0,
      reason: 'stdout: ${result.stdout}\nstderr: ${result.stderr}',
    );
    expect(
      result.stdout,
      contains('Staged standalone/lib: 0 transformed, 0 symlinked.'),
    );
  });

  test('weaves and tests a nested workspace member', () async {
    final workspaceDir = Directory('${tempDir.path}/workspace');
    final memberDir = Directory('${workspaceDir.path}/pkgs/standalone');
    memberDir.parent.createSync(recursive: true);
    packageDir.renameSync(memberDir.path);
    File('${workspaceDir.path}/pubspec.yaml').writeAsStringSync('''
name: workspace
environment:
  sdk: ^3.11.0
workspace:
  - pkgs/standalone
''');
    final memberPubspec = File('${memberDir.path}/pubspec.yaml');
    memberPubspec.writeAsStringSync(
      '${memberPubspec.readAsStringSync()}resolution: workspace\n',
    );

    final result = await _runWeaver('${memberDir.path}/test', [
      '--stage-dir=${tempDir.path}/stage',
    ]);
    expect(
      result.exitCode,
      0,
      reason: 'stdout: ${result.stdout}\nstderr: ${result.stderr}',
    );
    expect(
      result.stdout,
      contains('Staged pkgs/standalone/lib: 2 transformed, 0 symlinked.'),
    );
  });

  // Overlap and layout errors are covered in process by `stager_test.dart` and
  // `package_layout_finder_test.dart`. This checks that one reaches the user.
  test('reports an error and fails before touching anything', () async {
    final result = await _runWeaver(packageDir.path, [
      '--stage-dir=${tempDir.path}',
    ]);
    expect(result.exitCode, 1);
    expect(
      result.stderr,
      startsWith('Error: --stage-dir must not contain or be inside'),
    );
    expect(File('${packageDir.path}/pubspec.yaml').existsSync(), isTrue);
  });
}
