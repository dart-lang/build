// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart';
import 'package:build_compilers/build_compilers.dart';
import 'package:build_runner/build_runner.dart';
import 'package:build_test/builder.dart';

Future main(List<String> args) async {
  var builders = [
    apply('e2e_example', 'throwing_builder', [(_) => new ThrowingBuilder()],
        toRoot(),
        hideOutput: true),
    apply('build_test', 'test_bootstrap', [(_) => new TestBootstrapBuilder()],
        toRoot(),
        inputs: ['test/**_test.dart'], hideOutput: true),
    apply(
        'build_compilers',
        'ddc',
        [
          (_) => new ModuleBuilder(),
          (_) => new UnlinkedSummaryBuilder(),
          (_) => new LinkedSummaryBuilder(),
          (_) => new DevCompilerBuilder()
        ],
        toAllPackages(),
        isOptional: true,
        hideOutput: true),
    apply('build_compilers', 'ddc_boostrap',
        [(_) => new DevCompilerBootstrapBuilder()], toRoot(),
        inputs: ['web/**.dart', 'test/**.browser_test.dart'], hideOutput: true)
  ];

  await run(args, builders);
}

class ThrowingBuilder extends Builder {
  @override
  final buildExtensions = {
    '.fail': ['.fail.message']
  };

  @override
  Future<Null> build(BuildStep buildStep) async {
    throw await buildStep.readAsString(buildStep.inputId);
  }
}
