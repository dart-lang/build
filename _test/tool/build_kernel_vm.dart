// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build_config/build_config.dart';
import 'package:build_modules/builders.dart';
import 'package:build_vm_compilers/builders.dart';
import 'package:build_runner/build_runner.dart';
import 'package:build_test/builder.dart';

Future main(List<String> args) async {
  var builders = [
    apply('_test|test_bootstrap', [(_) => new TestBootstrapBuilder()], toRoot(),
        defaultGenerateFor:
            const InputSet(include: const ['test/**_test.dart']),
        hideOutput: true),
    apply(
        '_test|vm_kernel',
        [
          metaModuleBuilder,
          metaModuleCleanBuilder,
          moduleBuilder,
          vmKernelModuleBuilder,
        ],
        toAllPackages(),
        isOptional: true,
        hideOutput: true),
    apply(
        '_test|entrypoint',
        [
          vmKernelEntrypointBuilder,
        ],
        toRoot(),
        defaultGenerateFor: const InputSet(include: const [
          'bin/**.dart',
          'tool/**.dart',
          'test/**.vm_test.dart',
        ]),
        hideOutput: true)
  ];

  await run(args, builders);
}
