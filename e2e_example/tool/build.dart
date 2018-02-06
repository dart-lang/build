// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:build/build.dart';
import 'package:build_web_compilers/build_web_compilers.dart';
import 'package:build_modules/build_modules.dart';
import 'package:build_config/build_config.dart';
import 'package:build_runner/build_runner.dart';
import 'package:build_test/builder.dart';

Future main(List<String> args) async {
  var builders = [
    apply('e2e_example|throwing_builder', [(_) => new ThrowingBuilder()],
        toRoot(),
        hideOutput: true),
    apply('build_test|test_bootstrap', [(_) => new TestBootstrapBuilder()],
        toRoot(),
        hideOutput: true,
        defaultGenerateFor:
            const InputSet(include: const ['test/**_test.dart'])),
    apply(
        'build_modules|modules',
        [
          (_) => new ModuleBuilder(),
          (_) => new UnlinkedSummaryBuilder(),
          (_) => new LinkedSummaryBuilder(),
        ],
        toAllPackages(),
        isOptional: true,
        hideOutput: true),
    apply('build_web_compilers|ddc', [(_) => new DevCompilerBuilder()],
        toAllPackages(),
        isOptional: true, hideOutput: true),
    apply('build_web_compilers|entrypoint',
        [(_) => new WebEntrypointBuilder(WebCompiler.DartDevc)], toRoot(),
        hideOutput: true,
        defaultGenerateFor: const InputSet(
            include: const ['web/**', 'test/**.browser_test.dart']))
  ];

  exitCode = await run(args, builders);
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
