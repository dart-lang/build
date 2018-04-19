// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'package:build_test/build_test.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

import 'package:build/build.dart';
import 'package:build_modules/build_modules.dart';
import 'package:build_modules/src/meta_module.dart';

import 'matchers.dart';
import 'util.dart';

main() {
  Map<String, dynamic> assets;

  group('basic project', () {
    setUp(() async {
      var a = new AssetId('a', 'lib/a.dart');
      var ameta = new MetaModule([
        new Module(a, [a], [])
      ]);
      var b = new AssetId('b', 'lib/b.dart');
      var bmeta = new MetaModule([
        new Module(b, [b], [])
      ]);
      assets = {
        'build_modules|lib/src/analysis_options.default.yaml': '',
        'a|lib/.meta_module': json.encode(ameta),
        'b|lib/.meta_module': json.encode(bmeta),
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
      await testBuilderAndCollectAssets(new ModuleBuilder(), assets);
    });

    test('can output unlinked analyzer summaries for modules under lib and web',
        () async {
      var expectedOutputs = <String, Matcher>{
        'b|lib/b.unlinked.sum': new HasUnlinkedUris(['package:b/b.dart']),
        'a|lib/a.unlinked.sum': new HasUnlinkedUris(['package:a/a.dart']),
        'a|web/index.unlinked.sum':
            new HasUnlinkedUris([endsWith('web/index.dart')]),
      };
      await testBuilder(new UnlinkedSummaryBuilder(), assets,
          outputs: expectedOutputs);
    });

    test('can output linked analyzer summaries for modules under lib and web',
        () async {
      // Build the unlinked summaries first.
      await testBuilderAndCollectAssets(new UnlinkedSummaryBuilder(), assets);

      // Actual test for LinkedSummaryBuilder;
      var expectedOutputs = <String, Matcher>{
        'b|lib/b.linked.sum': allOf(new HasLinkedUris(['package:b/b.dart']),
            new HasUnlinkedUris(['package:b/b.dart'])),
        'a|lib/a.linked.sum': allOf(
            new HasLinkedUris(
                unorderedEquals(['package:b/b.dart', 'package:a/a.dart'])),
            new HasUnlinkedUris(['package:a/a.dart'])),
        'a|web/index.linked.sum': allOf(
            new HasLinkedUris(unorderedEquals([
              'package:b/b.dart',
              'package:a/a.dart',
              endsWith('web/index.dart')
            ])),
            new HasUnlinkedUris([endsWith('web/index.dart')])),
      };
      await testBuilder(new LinkedSummaryBuilder(), assets,
          outputs: expectedOutputs);
    });
  });

  group('linked summaries with missing imports', () {
    setUp(() async {
      assets = {
        'build_modules|lib/src/analysis_options.default.yaml': '',
        'a|web/index.dart': 'import "package:a/a.dart";',
      };

      // Set up all the other required inputs for this test.
      await testBuilderAndCollectAssets(new ModuleBuilder(), assets);
      await testBuilderAndCollectAssets(new UnlinkedSummaryBuilder(), assets);
    });

    test('print an error if there are any missing transitive modules',
        () async {
      var expectedOutputs = <String, Matcher>{};
      var logs = <LogRecord>[];
      await testBuilder(new LinkedSummaryBuilder(), assets,
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
