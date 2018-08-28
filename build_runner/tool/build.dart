// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:build_config/build_config.dart';
import 'package:build_modules/builders.dart';
import 'package:build_runner/build_runner.dart';
import 'package:build_web_compilers/builders.dart';

main(List<String> args) async {
  await run(args, [
    apply(
        'build_modules|modules',
        [
          moduleLibraryBuilder,
          metaModuleBuilder,
          metaModuleCleanBuilder,
          moduleBuilder,
        ],
        toAllPackages(),
        isOptional: true,
        hideOutput: true),
    apply(
        'build_web_compilers|entrypoint',
        [
          (_) => webEntrypointBuilder(BuilderOptions({
                'compiler': 'dart2js',
                'dart2js_args': ['--minify', '--omit-implicit-checks']
              }))
        ],
        toAllPackages(),
        isOptional: false,
        hideOutput: false,
        defaultGenerateFor: InputSet(include: [
          'lib/src/server/graph_viz_main.dart',
          'lib/src/server/build_updates_client/hot_reload_client.dart',
        ])),
  ]);
}
