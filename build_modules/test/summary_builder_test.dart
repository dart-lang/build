// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build_test/build_test.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

import 'package:build_modules/build_modules.dart';

import 'matchers.dart';
import 'util.dart';

main() {
  Map<String, dynamic> assets;
  final platform = DartPlatform.dart2js;

  group('basic project', () {
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
    });

    test('can output unlinked analyzer summaries for modules under lib and web',
        () async {
      var expectedOutputs = <String, Matcher>{
        'b|lib/b${unlinkedSummaryExtension(platform)}':
            HasUnlinkedUris(['package:b/b.dart']),
        'a|lib/a${unlinkedSummaryExtension(platform)}':
            HasUnlinkedUris(['package:a/a.dart']),
        'a|web/index${unlinkedSummaryExtension(platform)}':
            HasUnlinkedUris([endsWith('web/index.dart')]),
      };
      await testBuilder(UnlinkedSummaryBuilder(platform), assets,
          outputs: expectedOutputs);
    });

    test('can output linked analyzer summaries for modules under lib and web',
        () async {
      // Build the unlinked summaries first.
      await testBuilderAndCollectAssets(
          UnlinkedSummaryBuilder(platform), assets);

      // Actual test for LinkedSummaryBuilder;
      var expectedOutputs = <String, Matcher>{
        'b|lib/b${linkedSummaryExtension(platform)}': allOf(
            HasLinkedUris(['package:b/b.dart']),
            HasUnlinkedUris(['package:b/b.dart'])),
        'a|lib/a${linkedSummaryExtension(platform)}': allOf(
            HasLinkedUris(
                unorderedEquals(['package:b/b.dart', 'package:a/a.dart'])),
            HasUnlinkedUris(['package:a/a.dart'])),
        'a|web/index${linkedSummaryExtension(platform)}': allOf(
            HasLinkedUris(unorderedEquals([
              'package:b/b.dart',
              'package:a/a.dart',
              endsWith('web/index.dart')
            ])),
            HasUnlinkedUris([endsWith('web/index.dart')])),
      };
      await testBuilder(LinkedSummaryBuilder(platform), assets,
          outputs: expectedOutputs);
    });
  });

  group('linked summaries with missing imports', () {
    setUp(() async {
      assets = {
        'build_modules|lib/src/analysis_options.default.yaml': '',
        'a|web/index.dart': 'import "package:a/a.dart";',
        'a|lib/a.dart': 'import "package:b/b.dart";',
      };

      // Set up all the other required inputs for this test.
      await testBuilderAndCollectAssets(const ModuleLibraryBuilder(), assets);
      await testBuilderAndCollectAssets(MetaModuleBuilder(platform), assets);
      await testBuilderAndCollectAssets(
          MetaModuleCleanBuilder(platform), assets);
      await testBuilderAndCollectAssets(ModuleBuilder(platform), assets);
      await testBuilderAndCollectAssets(
          UnlinkedSummaryBuilder(platform), assets);
    });

    test('print an error if there are any missing transitive modules',
        () async {
      var expectedOutputs = <String, Matcher>{};
      var logs = <LogRecord>[];
      await testBuilder(LinkedSummaryBuilder(platform), assets,
          outputs: expectedOutputs, onLog: logs.add);
      expect(
          logs,
          contains(predicate<LogRecord>((record) =>
              record.level == Level.SEVERE &&
              record.message
                  .contains('Unable to find modules for some sources'))));
    });
  });
}
