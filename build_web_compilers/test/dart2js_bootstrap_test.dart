// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/experiments.dart';
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
          MetaModuleCleanBuilder(platform), assets);
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
          WebEntrypointBuilder(WebCompiler.Dart2Js,
              soundNullSafetyOverride: null,
              nullAssertions: false,
              nativeNullAssertions: false),
          assets,
          outputs: expectedOutputs);
    });

    test('works with --no-sourcemap', () async {
      var expectedOutputs = {
        'a|web/index.dart.js': anything,
        'a|web/index.dart.js.tar.gz': anything,
      };
      await testBuilder(
          WebEntrypointBuilder(WebCompiler.Dart2Js,
              dart2JsArgs: ['--no-source-maps'],
              soundNullSafetyOverride: null,
              nullAssertions: false,
              nativeNullAssertions: false),
          assets,
          outputs: expectedOutputs);
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
        WebEntrypointBuilder(WebCompiler.Dart2Js,
            soundNullSafetyOverride: null,
            nullAssertions: false,
            nativeNullAssertions: false),
        assets,
        outputs: expectedOutputs);
  });

  group('null safety', () {
    test('sound null safety is defaulted based on the entrypoint', () async {
      assets = {
        'a|lib/is_sound.dart': '''
        // @dart=2.10
        const unsoundMode = <int?>[] is List<int>;
        ''',
        'a|web/sound.dart': '''
        // @dart=2.10
        import 'package:a/is_sound.dart';
        void main() {
          print(unsoundMode);
        }
      ''',
        'a|web/unsound.dart': '''
        // @dart=2.9
        import 'package:a/is_sound.dart';
        void main() {
          print(unsoundMode);
        }
      ''',
      };

      await withEnabledExperiments(() async {
        // Set up all the other required inputs for this test.
        await testBuilderAndCollectAssets(const ModuleLibraryBuilder(), assets);
        await testBuilderAndCollectAssets(MetaModuleBuilder(platform), assets);
        await testBuilderAndCollectAssets(
            MetaModuleCleanBuilder(platform), assets);
        await testBuilderAndCollectAssets(ModuleBuilder(platform), assets);
        // Check the inlined constant value for soundness
        var expectedOutputs = {
          'a|web/sound.dart.js': decodedMatches(allOf(
              contains('NullSafetyMode.sound'),
              isNot(contains('NullSafetyMode.unsound')))),
          'a|web/sound.dart.js.map': anything,
          'a|web/sound.dart.js.tar.gz': anything,
          'a|web/unsound.dart.js': decodedMatches(allOf(
              contains('NullSafetyMode.unsound'),
              isNot(contains('NullSafetyMode.sound')))),
          'a|web/unsound.dart.js.map': anything,
          'a|web/unsound.dart.js.tar.gz': anything,
        };
        await testBuilder(
            WebEntrypointBuilder(WebCompiler.Dart2Js,
                soundNullSafetyOverride: null,
                nullAssertions: false,
                nativeNullAssertions: false),
            assets,
            outputs: expectedOutputs);
      }, ['non-nullable']);
    });
  });
}
