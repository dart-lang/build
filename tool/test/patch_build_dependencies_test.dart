// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:build_development_tools/patch_build_dependencies.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

void main() {
  test('without previous overrides', () {
    return _testTransformation(
      '''
name: test
environment:
  sdk: ^2.12.0

dependencies:
  foo: ^1.0.0

dev_dependencies:
  bar: ^1.2.3
''',
      '''
name: test
environment:
  sdk: ^2.12.0

dependencies:
  foo: ^1.0.0

dev_dependencies:
  bar: ^1.2.3
dependency_overrides: {build: {path: ${_packagePath('build')}}, build_config: {path: ${_packagePath('build_config')}}, build_daemon: {path: ${_packagePath('build_daemon')}}, build_modules: {path: ${_packagePath('build_modules')}}, build_resolvers: {path: ${_packagePath('build_resolvers')}}, build_runner: {path: ${_packagePath('build_runner')}}, build_runner_core: {path: ${_packagePath('build_runner_core')}}, build_test: {path: ${_packagePath('build_test')}}, build_vm_compilers: {path: ${_packagePath('build_vm_compilers')}}, build_web_compilers: {path: ${_packagePath('build_web_compilers')}}, scratch_space: {path: ${_packagePath('scratch_space')}}}
''',
    );
  });

  test('with existing overrides', () {
    return _testTransformation(
      '''
name: test
environment:
  sdk: ^2.12.0

dependencies:
  foo: ^1.0.0

dev_dependencies:
  bar: ^1.2.3

dependency_overrides:
  unrelated: ^1.0.0
  build_runner: ^1.2.3
''',
      '''
name: test
environment:
  sdk: ^2.12.0

dependencies:
  foo: ^1.0.0

dev_dependencies:
  bar: ^1.2.3

dependency_overrides:
  unrelated: ^1.0.0
  build_runner: 
    path: ${_packagePath('build_runner')}
  build: 
    path: ${_packagePath('build')}
  build_config: 
    path: ${_packagePath('build_config')}
  build_daemon: 
    path: ${_packagePath('build_daemon')}
  build_modules: 
    path: ${_packagePath('build_modules')}
  build_resolvers: 
    path: ${_packagePath('build_resolvers')}
  build_runner_core: 
    path: ${_packagePath('build_runner_core')}
  build_test: 
    path: ${_packagePath('build_test')}
  build_vm_compilers: 
    path: ${_packagePath('build_vm_compilers')}
  build_web_compilers: 
    path: ${_packagePath('build_web_compilers')}
  scratch_space: 
    path: ${_packagePath('scratch_space')}
''',
    );
  });
}

String _packagePath(String package) {
  return p.join(Directory.current.path, package);
}

Future<void> _testTransformation(String old, String updated) async {
  await d.dir('package', [d.file('pubspec.yaml', old)]).create();
  await patchBuildDependencies(p.join(d.sandbox, 'package'));
  await d.dir('package', [d.file('pubspec.yaml', updated)]).validate();
}
