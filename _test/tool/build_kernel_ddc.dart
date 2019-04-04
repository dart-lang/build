// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build_config/build_config.dart';
import 'package:build_web_compilers/builders.dart';
import 'package:build_web_compilers/build_web_compilers.dart';
import 'package:build_modules/build_modules.dart';
import 'package:build_modules/builders.dart';
import 'package:build_runner/build_runner.dart';
import 'package:build_runner_core/build_runner_core.dart';
import 'package:build_test/builder.dart';

Future main(List<String> args) async {
  var builders = [
    apply('_test|test_bootstrap', [(_) => TestBootstrapBuilder()], toRoot(),
        defaultGenerateFor: const InputSet(include: ['test/**_test.dart']),
        hideOutput: true),
    apply(
        '_test|ddc_kernel',
        [
          moduleLibraryBuilder,
          metaModuleBuilderFactoryForPlatform(DartPlatform.dartdevc.name),
          metaModuleCleanBuilderFactoryForPlatform(DartPlatform.dartdevc.name),
          moduleBuilderFactoryForPlatform(DartPlatform.dartdevc.name),
          ddcKernelBuilder,
        ],
        toAllPackages(),
        isOptional: true,
        hideOutput: true),
    apply(
        'build_web_compilers|ddc',
        [
          (_) => DevCompilerBuilder(),
        ],
        toAllPackages(),
        isOptional: true,
        hideOutput: true),
    apply('build_web_compilers|entrypoint',
        [(_) => WebEntrypointBuilder(WebCompiler.DartDevc)], toRoot(),
        defaultGenerateFor: const InputSet(include: [
          'web/**.dart',
          'test/**.browser_test.dart',
        ]),
        hideOutput: true)
  ];

  await run(args, builders);
}
