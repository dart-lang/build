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

void main() {
  initializePlatforms();
  final platform = dart2jsPlatform;

  late StreamSubscription<LogRecord> logSubscription;
  setUp(() {
    Logger.root.level = Level.ALL;
    logSubscription = Logger.root.onRecord.listen((r) => printOnFailure('$r'));
  });

  tearDown(() async {
    await logSubscription.cancel();
  });

  group('dart2js', () {
    final startingAssets = {
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
      'b|lib/b.dart': '''final world = 'world';''',
    };
    final startingBuilders = [
      const ModuleLibraryBuilder(),
      MetaModuleBuilder(platform),
      MetaModuleCleanBuilder(platform),
      ModuleBuilder(platform),
    ];
    final startingExpectedOutputs = {
      'a|lib/.dart2js.meta_module.clean': isNotNull,
      'a|lib/.dart2js.meta_module.raw': isNotNull,
      'a|lib/a.dart2js.module': isNotNull,
      'a|lib/a.module.library': isNotNull,
      'a|web/index.dart2js.module': isNotNull,
      'a|web/index.module.library': isNotNull,
      'b|lib/.dart2js.meta_module.clean': isNotNull,
      'b|lib/.dart2js.meta_module.raw': isNotNull,
      'b|lib/b.dart2js.module': isNotNull,
      'b|lib/b.module.library': isNotNull,
    };

    test('base build', () async {
      await testBuilders(
        startingBuilders,
        startingAssets,
        outputs: startingExpectedOutputs,
      );
    });

    test('can bootstrap dart entrypoints', () async {
      // Just do some basic sanity checking, integration tests will validate
      // things actually work.
      final builder = WebEntrypointBuilder.fromOptions(
        const BuilderOptions({
          'compiler': 'dart2js',
          'native_null_assertions': false,
        }),
      );
      final expectedOutputs = Map.of(startingExpectedOutputs)..addAll({
        'a|web/index.dart.js.map': isNotNull,
        'a|web/index.dart.js.tar.gz': isNotNull,
        'a|web/index.dart.js': decodedMatches(contains('world')),
      });
      await testBuilders(
        [...startingBuilders, builder],
        startingAssets,
        outputs: expectedOutputs,
      );
    });

    test('works with --no-sourcemap', () async {
      final builder = WebEntrypointBuilder.fromOptions(
        const BuilderOptions({
          'compiler': 'dart2js',
          'native_null_assertions': false,
          'dart2js_args': ['--no-source-maps'],
        }),
      );
      final expectedOutputs = Map.of(startingExpectedOutputs)..addAll({
        'a|web/index.dart.js.tar.gz': anything,
        'a|web/index.dart.js': anything,
      });
      await testBuilders(
        [...startingBuilders, builder],
        startingAssets,
        outputs: expectedOutputs,
      );
    });
  });

  test('dart2js can bootstrap apps under lib', () async {
    // Just do some basic sanity checking, integration tests will validate
    // things actually work.
    final assets = {
      'a|lib/index.dart': '''
        main() {
          print('hello world');
        }
      ''',
    };
    final expectedOutputs = {
      'a|lib/.dart2js.meta_module.clean': isNotNull,
      'a|lib/.dart2js.meta_module.raw': isNotNull,
      'a|lib/index.dart.js.map': isNotNull,
      'a|lib/index.dart.js.tar.gz': isNotNull,
      'a|lib/index.dart.js': decodedMatches(contains('world')),
      'a|lib/index.dart2js.module': isNotNull,
      'a|lib/index.module.library': isNotNull,
    };
    await testBuilders(
      [
        const ModuleLibraryBuilder(),
        MetaModuleBuilder(platform),
        MetaModuleCleanBuilder(platform),
        ModuleBuilder(platform),
        WebEntrypointBuilder.fromOptions(
          const BuilderOptions({
            'compiler': 'dart2js',
            'native_null_assertions': false,
          }),
        ),
      ],
      assets,
      outputs: expectedOutputs,
    );
  });

  test('throws on unsupported platform library imports', () async {
    final assets = {
      'a|lib/index.dart': '''
        import 'dart:io';
        main() {
          print('hello world');
        }
      ''',
    };
    final expectedOutputs = {
      'a|lib/.dart2js.meta_module.clean': isNotNull,
      'a|lib/.dart2js.meta_module.raw': isNotNull,
      'a|lib/index.dart2js.module': isNotNull,
      'a|lib/index.module.library': isNotNull,
    };
    final logs = <LogRecord>[];
    await testBuilders(
      [
        const ModuleLibraryBuilder(),
        MetaModuleBuilder(platform),
        MetaModuleCleanBuilder(platform),
        ModuleBuilder(platform),
        WebEntrypointBuilder.fromOptions(
          const BuilderOptions({
            'compiler': 'dart2js',
            'native_null_assertions': false,
          }),
        ),
      ],
      assets,
      outputs: expectedOutputs,
      onLog: logs.add,
    );
    expect(
      logs,
      contains(
        isA<LogRecord>().having(
          (r) => r.message,
          'message',
          contains(
            'Skipping compiling a|lib/index.dart with dart2js because some of '
            'its\ntransitive libraries have sdk dependencies that are not '
            'supported on this platform:\n\na|lib/index.dart',
          ),
        ),
      ),
    );
  });

  test(
    'ignores unsupported platform library imports when allow flag is set',
    () async {
      final assets = {
        'a|lib/index.dart': '''
        import 'dart:io';
        main() {
          print('hello world');
        }
      ''',
      };
      final expectedOutputs = {
        'a|lib/.dart2js.meta_module.clean': isNotNull,
        'a|lib/.dart2js.meta_module.raw': isNotNull,
        'a|lib/index.dart.js.map': isNotNull,
        'a|lib/index.dart.js.tar.gz': isNotNull,
        'a|lib/index.dart.js': decodedMatches(contains('world')),
        'a|lib/index.dart2js.module': isNotNull,
        'a|lib/index.module.library': isNotNull,
      };
      await testBuilders(
        [
          const ModuleLibraryBuilder(),
          MetaModuleBuilder(platform),
          MetaModuleCleanBuilder(platform),
          ModuleBuilder(platform),
          WebEntrypointBuilder.fromOptions(
            const BuilderOptions({
              'compiler': 'dart2js',
              'native_null_assertions': false,
              'unsafe_allow_unsupported_modules': true,
            }),
          ),
        ],
        assets,
        outputs: expectedOutputs,
      );
    },
  );
}
