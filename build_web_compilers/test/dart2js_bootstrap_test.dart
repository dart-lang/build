// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart';
import 'package:build_modules/build_modules.dart';
import 'package:build_test/build_test.dart';
import 'package:build_web_compilers/build_web_compilers.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

import 'util.dart';

void main() {
  late Map<String, Object> assets;
  final platform = dart2jsPlatform;

  late StreamSubscription<LogRecord> logSubscription;
  setUp(() {
    Logger.root.level = Level.ALL;
    logSubscription = Logger.root.onRecord.listen((r) => printOnFailure('$r'));
  });

  tearDown(() {
    logSubscription.cancel();
  });

  group('dart2js', () {
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
      };

      // Set up all the other required inputs for this test.
      await testBuilderAndCollectAssets(const ModuleLibraryBuilder(), assets);
      await testBuilderAndCollectAssets(MetaModuleBuilder(platform), assets);
      await testBuilderAndCollectAssets(
        MetaModuleCleanBuilder(platform),
        assets,
      );
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
      await testBuilder(
        WebEntrypointBuilder.fromOptions(
          const BuilderOptions({
            'compiler': 'dart2js',
            'native_null_assertions': false,
          }),
        ),
        assets,
        outputs: expectedOutputs,
      );
    });

    test('works with --no-sourcemap', () async {
      var expectedOutputs = {
        'a|web/index.dart.js': anything,
        'a|web/index.dart.js.tar.gz': anything,
      };
      await testBuilder(
        WebEntrypointBuilder.fromOptions(
          const BuilderOptions({
            'compiler': 'dart2js',
            'native_null_assertions': false,
            'dart2js_args': ['--no-source-maps'],
          }),
        ),
        assets,
        outputs: expectedOutputs,
      );
    });
  });

  test('dart2js can bootstrap apps under lib', () async {
    assets = {
      'a|lib/index.dart': '''
        main() {
          print('hello world');
        }
      ''',
    };

    // Set up all the other required inputs for this test.
    await testBuilderAndCollectAssets(const ModuleLibraryBuilder(), assets);
    await testBuilderAndCollectAssets(MetaModuleBuilder(platform), assets);
    await testBuilderAndCollectAssets(MetaModuleCleanBuilder(platform), assets);
    await testBuilderAndCollectAssets(ModuleBuilder(platform), assets);

    // Just do some basic sanity checking, integration tests will validate
    // things actually work.
    var expectedOutputs = {
      'a|lib/index.dart.js': decodedMatches(contains('world')),
      'a|lib/index.dart.js.map': anything,
      'a|lib/index.dart.js.tar.gz': anything,
    };
    await testBuilder(
      WebEntrypointBuilder.fromOptions(
        const BuilderOptions({
          'compiler': 'dart2js',
          'native_null_assertions': false,
        }),
      ),
      assets,
      outputs: expectedOutputs,
    );
  });
}
