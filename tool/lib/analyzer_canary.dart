// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// Checks that the published `build_runner` works with `analyzer` at HEAD of
/// dart-lang/sdk.
///
/// Creates a package in [workDir] that uses the latest published
/// `build_runner` and `built_value_generator`, overrides `analyzer` with HEAD,
/// and runs a build.
///
/// Throws a [ProcessException] if any step fails.
Future<void> runAnalyzerCanary(String workDir) async {
  final sdkDir = p.join(workDir, 'sdk');
  final packageDir = p.join(workDir, 'canary');

  await _run('git', [
    'clone',
    '--depth',
    '1',
    '--filter=blob:none',
    '--sparse',
    'https://github.com/dart-lang/sdk.git',
    sdkDir,
  ]);
  await _run('git', [
    '-C',
    sdkDir,
    'sparse-checkout',
    'set',
    'pkg/analyzer',
    'pkg/_fe_analyzer_shared',
  ]);
  await _run('git', ['-C', sdkDir, 'log', '-1', '--format=%H %s']);

  // In the SDK repo these packages resolve as part of its pub workspace; drop
  // that so they can be used as path dependencies.
  for (final package in ['analyzer', '_fe_analyzer_shared']) {
    final pubspec = File(p.join(sdkDir, 'pkg', package, 'pubspec.yaml'));
    pubspec.writeAsStringSync(
      pubspec.readAsStringSync().replaceAll(
        RegExp(r'^resolution: workspace$', multiLine: true),
        '',
      ),
    );
  }

  _writePackage(packageDir, sdkDir);
  await _run('dart', ['pub', 'get'], workingDirectory: packageDir);
  await _run('dart', [
    'run',
    'build_runner',
    'build',
  ], workingDirectory: packageDir);
}

void _writePackage(String packageDir, String sdkDir) {
  Directory(p.join(packageDir, 'lib')).createSync(recursive: true);
  final analyzer = p.absolute(sdkDir, 'pkg', 'analyzer');
  final feAnalyzerShared = p.absolute(sdkDir, 'pkg', '_fe_analyzer_shared');
  File(p.join(packageDir, 'pubspec.yaml')).writeAsStringSync('''
name: analyzer_canary
publish_to: none
environment:
  sdk: ^3.11.0
dependencies:
  built_value: any
dev_dependencies:
  build_runner: any
  built_value_generator: any
dependency_overrides:
  analyzer:
    path: ${jsonEncode(analyzer)}
  _fe_analyzer_shared:
    path: ${jsonEncode(feAnalyzerShared)}
''');
  // A builder that resolves code, so the build uses the analyzer API rather
  // than only compiling against it.
  File(p.join(packageDir, 'lib', 'value.dart')).writeAsStringSync(r'''
import 'package:built_value/built_value.dart';

part 'value.g.dart';

abstract class Value implements Built<Value, ValueBuilder> {
  int get x;
  Value._();
  factory Value([void Function(ValueBuilder) updates]) = _$Value;
}
''');
}

/// Runs [executable] with its output going to this process's output, throwing
/// a [ProcessException] if it fails.
Future<void> _run(
  String executable,
  List<String> arguments, {
  String? workingDirectory,
}) async {
  print('> $executable ${arguments.join(' ')}');
  final process = await Process.start(
    executable,
    arguments,
    workingDirectory: workingDirectory,
    mode: ProcessStartMode.inheritStdio,
  );
  final exitCode = await process.exitCode;
  if (exitCode != 0) {
    throw ProcessException(executable, arguments, '', exitCode);
  }
}
