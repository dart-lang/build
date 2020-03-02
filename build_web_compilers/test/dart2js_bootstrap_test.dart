// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import 'package:build_web_compilers/build_web_compilers.dart';
import 'package:build_modules/build_modules.dart';

import 'util.dart';

void main() {
  Map<String, dynamic> assets;
  final platform = dart2jsPlatform;

  setUp(() async {
    assets = {
      'b|lib/b.dart': '''final world = 'world';''',
      'a|lib/a.dart': '''
        import 'package:b/b.dart';
        final hello = world;
      ''',
      'a|web/index.dart': '''
        import "package:a/a.dart";
        main() {
          print(hello);
        }
      ''',
      'a|.dart_tool/package_config.json': jsonEncode({
        'configVersion': 2,
        'packages': [
          for (var pkg in ['a', 'b'])
            {'name': pkg, 'rootUri': 'packages/a', 'packageUri': ''}
        ]
      }),
    };

    // Set up all the other required inputs for this test.
    await testBuilderAndCollectAssets(const ModuleLibraryBuilder(), assets);
    await testBuilderAndCollectAssets(MetaModuleBuilder(platform), assets);
    await testBuilderAndCollectAssets(MetaModuleCleanBuilder(platform), assets);
    await testBuilderAndCollectAssets(ModuleBuilder(platform), assets);
  });

  test('can bootstrap dart entrypoints', () async {
    // Just do some basic sanity checking, integration tests will validate
    // things actually work.
    var expectedOutputs = {
      'a|web/index.dart.js': decodedMatches(contains('world')),
      'a|web/index.dart.js.map': anything,
      'a|web/index.dart.js.tar.gz': anything,
    };
    await testBuilder(WebEntrypointBuilder(WebCompiler.Dart2Js), assets,
        outputs: expectedOutputs);
  });

  test('works with --no-sourcemap', () async {
    var expectedOutputs = {
      'a|web/index.dart.js': anything,
      'a|web/index.dart.js.tar.gz': anything,
    };
    await testBuilder(
        WebEntrypointBuilder(WebCompiler.Dart2Js,
            dart2JsArgs: ['--no-source-maps']),
        assets,
        outputs: expectedOutputs);
  });
}
