// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build_test/build_test.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

import 'package:build_web_compilers/build_web_compilers.dart';
import 'package:build_modules/build_modules.dart';

import 'util.dart';

main() {
  Map<String, dynamic> assets;

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
        r'$sdk|lib/libraries.json': '{"dartdevc": {}}',
      };

      // Set up all the other required inputs for this test.
      await testBuilderAndCollectAssets(const ModuleLibraryBuilder(), assets);
      await testBuilderAndCollectAssets(MetaModuleBuilder('dartdevc'), assets);
      await testBuilderAndCollectAssets(
          MetaModuleCleanBuilder('dartdevc'), assets);
      await testBuilderAndCollectAssets(ModuleBuilder('dartdevc'), assets);
      await testBuilderAndCollectAssets(
          UnlinkedSummaryBuilder('dartdevc'), assets);
      await testBuilderAndCollectAssets(
          LinkedSummaryBuilder('dartdevc'), assets);
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
          r'$sdk|lib/libraries.json': '{"dartdevc": {}}',
          'a|web/index.dart': 'int x = "hello";',
        };

        // Set up all the other required inputs for this test.
        await testBuilderAndCollectAssets(const ModuleLibraryBuilder(), assets);
        await testBuilderAndCollectAssets(
            MetaModuleBuilder('dartdevc'), assets);
        await testBuilderAndCollectAssets(
            MetaModuleCleanBuilder('dartdevc'), assets);
        await testBuilderAndCollectAssets(ModuleBuilder('dartdevc'), assets);
        await testBuilderAndCollectAssets(
            UnlinkedSummaryBuilder('dartdevc'), assets);
        await testBuilderAndCollectAssets(
            LinkedSummaryBuilder('dartdevc'), assets);
      });

      test('reports useful messages', () async {
        var expectedOutputs = {
          'a|web/index$jsModuleErrorsExtension': decodedMatches(
              allOf(contains('String'), contains('assigned'), contains('int'))),
        };
        var logs = <LogRecord>[];
        await testBuilder(DevCompilerBuilder(), assets,
            outputs: expectedOutputs, onLog: logs.add);
        expect(
            logs,
            contains(predicate<LogRecord>((record) =>
                record.level == Level.SEVERE &&
                record.message.contains('String') &&
                record.message.contains('assigned') &&
                record.message.contains('int'))));
      });
    });

    group('invalid imports', () {
      setUp(() async {
        assets = {
          'build_modules|lib/src/analysis_options.default.yaml': '',
          r'$sdk|lib/libraries.json': '{"dartdevc": {}}',
          'a|web/index.dart': "import 'package:a/a.dart'",
        };

        // Set up all the other required inputs for this test.
        await testBuilderAndCollectAssets(const ModuleLibraryBuilder(), assets);
        await testBuilderAndCollectAssets(
            MetaModuleBuilder('dartdevc'), assets);
        await testBuilderAndCollectAssets(
            MetaModuleCleanBuilder('dartdevc'), assets);
        await testBuilderAndCollectAssets(ModuleBuilder('dartdevc'), assets);
      });

      test('reports useful messages', () async {
        var expectedOutputs = {
          'a|web/index$jsModuleErrorsExtension': decodedMatches(
              contains('Unable to find modules for some sources')),
        };
        var logs = <LogRecord>[];
        await testBuilder(DevCompilerBuilder(), assets,
            outputs: expectedOutputs, onLog: logs.add);
        expect(
            logs,
            contains(predicate<LogRecord>((record) =>
                record.level == Level.SEVERE &&
                record.message
                    .contains('Unable to find modules for some sources'))));
      });
    });
  });
}
