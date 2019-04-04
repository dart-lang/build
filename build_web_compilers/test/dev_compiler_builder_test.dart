// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import 'package:build_web_compilers/build_web_compilers.dart';
import 'package:build_web_compilers/builders.dart';
import 'package:build_modules/build_modules.dart';

import 'util.dart';

main() {
  Map<String, dynamic> assets;
  final platform = DartPlatform.dartdevc;

  group('error free project', () {
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
      await testBuilderAndCollectAssets(
          MetaModuleCleanBuilder(platform), assets);
      await testBuilderAndCollectAssets(ModuleBuilder(platform), assets);
      await testBuilderAndCollectAssets(
          ddcKernelBuilder(BuilderOptions({})), assets);
    });

    test('can compile ddc modules under lib and web', () async {
      var expectedOutputs = {
        'b|lib/b$jsModuleExtension': decodedMatches(contains('world')),
        'b|lib/b$jsSourceMapExtension': decodedMatches(contains('b.dart')),
        'a|lib/a$jsModuleExtension': decodedMatches(contains('hello')),
        'a|lib/a$jsSourceMapExtension': decodedMatches(contains('a.dart')),
        'a|web/index$jsModuleExtension': decodedMatches(contains('main')),
        'a|web/index$jsSourceMapExtension':
            decodedMatches(contains('index.dart')),
      };
      await testBuilder(DevCompilerBuilder(), assets, outputs: expectedOutputs);
    });
  });

  group('projects with errors due to', () {
    group('invalid assignements', () {
      setUp(() async {
        assets = {
          'build_modules|lib/src/analysis_options.default.yaml': '',
          'a|web/index.dart': 'int x = "hello";',
        };

        // Set up all the other required inputs for this test.
        await testBuilderAndCollectAssets(const ModuleLibraryBuilder(), assets);
        await testBuilderAndCollectAssets(MetaModuleBuilder(platform), assets);
        await testBuilderAndCollectAssets(
            MetaModuleCleanBuilder(platform), assets);
        await testBuilderAndCollectAssets(ModuleBuilder(platform), assets);
        await testBuilderAndCollectAssets(
            ddcKernelBuilder(BuilderOptions({})), assets);
      });
    });

    group('invalid imports', () {
      setUp(() async {
        assets = {
          'build_modules|lib/src/analysis_options.default.yaml': '',
          'a|web/index.dart': "import 'package:a/a.dart'",
        };

        // Set up all the other required inputs for this test.
        await testBuilderAndCollectAssets(const ModuleLibraryBuilder(), assets);
        await testBuilderAndCollectAssets(MetaModuleBuilder(platform), assets);
        await testBuilderAndCollectAssets(
            MetaModuleCleanBuilder(platform), assets);
        await testBuilderAndCollectAssets(ModuleBuilder(platform), assets);
      });
    });
  });
}
