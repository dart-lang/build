// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import 'package:build_web_compilers/build_web_compilers.dart';
import 'package:build_modules/build_modules.dart';

import 'util.dart';

main() {
  Map<String, dynamic> assets;
  final platform = DartPlatform.dartdevc;

  setUp(() async {
    assets = {
      'build_modules|lib/src/analysis_options.default.yaml': '',
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
    };

    // Set up all the other required inputs for this test.
    await testBuilderAndCollectAssets(const ModuleLibraryBuilder(), assets);
    await testBuilderAndCollectAssets(MetaModuleBuilder(platform), assets);
    await testBuilderAndCollectAssets(MetaModuleCleanBuilder(platform), assets);
    await testBuilderAndCollectAssets(ModuleBuilder(platform), assets);
    await testBuilderAndCollectAssets(UnlinkedSummaryBuilder(platform), assets);
    await testBuilderAndCollectAssets(LinkedSummaryBuilder(platform), assets);
    await testBuilderAndCollectAssets(DevCompilerBuilder(), assets);
  });

  test('can bootstrap dart entrypoints', () async {
    // Just do some basic sanity checking, integration tests will validate
    // things actually work.
    var expectedOutputs = {
      'a|web/index.digests': decodedMatches(contains('packages/')),
      'a|web/index.dart.js': decodedMatches(contains('index.dart.bootstrap')),
      'a|web/index.dart.bootstrap.js': decodedMatches(allOf([
        // Maps non-lib modules to remove the top level dir.
        contains('"web/index": "index.ddc"'),
        // Maps lib modules to packages path
        contains('"packages/a/a": "packages/a/a.ddc"'),
        contains('"packages/b/b": "packages/b/b.ddc"'),
        // Requires the top level module and dart sdk.
        contains('define("index.dart.bootstrap", ["web/index", "dart_sdk"]'),
        // Calls main on the top level module.
        contains('index.main()'),
        isNot(contains('lib/a')),
      ])),
    };
    await testBuilder(WebEntrypointBuilder(WebCompiler.DartDevc), assets,
        outputs: expectedOutputs);
  });
}
