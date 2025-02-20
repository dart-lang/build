// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:build_modules/build_modules.dart';
import 'package:build_test/build_test.dart';
import 'package:build_web_compilers/build_web_compilers.dart';
import 'package:build_web_compilers/builders.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

import 'util.dart';

void main() {
  late Map<String, Object> assets;

  group('error free project ', () {
    setUp(() async {
      var listener = Logger.root.onRecord.listen(
        (r) => printOnFailure('$r\n${r.error}\n${r.stackTrace}'),
      );
      addTearDown(listener.cancel);
      assets = {
        'b|lib/b.dart': '''
        // @dart=2.12
        final world = 'world';''',
        'a|lib/a.dart': r'''
        // @dart=2.12
        import 'package:b/b.dart';
        final hello = 'hello $world';
      ''',
        'a|web/index.dart': '''
        // @dart=2.12
        import "package:a/a.dart";
        void main() {
          print(hello);
          print(const String.fromEnvironment('foo', defaultValue: 'bar'));
        }
      ''',
      };

      // Set up all the other required inputs for this test.
      await testBuilderAndCollectAssets(const ModuleLibraryBuilder(), assets);
      await testBuilderAndCollectAssets(MetaModuleBuilder(ddcPlatform), assets);
      await testBuilderAndCollectAssets(
        MetaModuleCleanBuilder(ddcPlatform),
        assets,
      );
      await testBuilderAndCollectAssets(ModuleBuilder(ddcPlatform), assets);
      await testBuilderAndCollectAssets(
        ddcKernelBuilder(const BuilderOptions({})),
        assets,
      );
    });

    for (var trackUnusedInputs in [true, false]) {
      test('can compile ddc modules under lib and web'
          '${trackUnusedInputs ? ' and track unused inputs' : ''}', () async {
        var expectedOutputs = {
          'b|lib/b$jsModuleExtension': decodedMatches(contains('world')),
          'b|lib/b$jsSourceMapExtension': decodedMatches(contains('b.dart')),
          'b|lib/b$metadataExtension': isNotEmpty,
          'a|lib/a$jsModuleExtension': decodedMatches(contains('hello')),
          'a|lib/a$jsSourceMapExtension': decodedMatches(contains('a.dart')),
          'a|lib/a$metadataExtension': isNotEmpty,
          'a|web/index$jsModuleExtension': decodedMatches(contains('main')),
          'a|web/index$jsSourceMapExtension': decodedMatches(
            contains('index.dart'),
          ),
          'a|web/index$metadataExtension': isNotEmpty,
        };
        var reportedUnused = <AssetId, Iterable<AssetId>>{};

        await testBuilder(
          DevCompilerBuilder(
            platform: ddcPlatform,
            useIncrementalCompiler: trackUnusedInputs,
            trackUnusedInputs: trackUnusedInputs,
          ),
          assets,
          outputs: expectedOutputs,
          reportUnusedAssetsForInput:
              (input, unused) => reportedUnused[input] = unused,
        );

        expect(
          reportedUnused[AssetId(
            'a',
            'web/index${moduleExtension(ddcPlatform)}',
          )],
          equals(
            trackUnusedInputs
                ? [AssetId('b', 'lib/b$ddcKernelExtension')]
                : null,
          ),
          reason:
              'Should${trackUnusedInputs ? '' : ' not'} report unused '
              'transitive deps.',
        );
      });
    }

    test('allows a custom environment', () async {
      var expectedOutputs = {
        'b|lib/b$jsModuleExtension': isNotEmpty,
        'b|lib/b$jsSourceMapExtension': isNotEmpty,
        'b|lib/b$metadataExtension': isNotEmpty,
        'a|lib/a$jsModuleExtension': isNotEmpty,
        'a|lib/a$jsSourceMapExtension': isNotEmpty,
        'a|lib/a$metadataExtension': isNotEmpty,
        'a|web/index$jsModuleExtension': decodedMatches(
          contains('print("zap")'),
        ),
        'a|web/index$jsSourceMapExtension': isNotEmpty,
        'a|web/index$metadataExtension': isNotEmpty,
      };
      await testBuilder(
        DevCompilerBuilder(platform: ddcPlatform, environment: {'foo': 'zap'}),
        assets,
        outputs: expectedOutputs,
      );
    });

    test('can enable DDC canary features', () async {
      var expectedOutputs = {
        'b|lib/b$jsModuleExtension': isNotEmpty,
        'b|lib/b$jsSourceMapExtension': isNotEmpty,
        'b|lib/b$metadataExtension': isNotEmpty,
        'a|lib/a$jsModuleExtension': decodedMatches(contains('canary')),
        'a|lib/a$jsSourceMapExtension': isNotEmpty,
        'a|lib/a$metadataExtension': isNotEmpty,
        'a|web/index$jsModuleExtension': isNotEmpty,
        'a|web/index$jsSourceMapExtension': isNotEmpty,
        'a|web/index$metadataExtension': isNotEmpty,
      };
      await testBuilder(
        DevCompilerBuilder(platform: ddcPlatform, canaryFeatures: true),
        assets,
        outputs: expectedOutputs,
      );
    });

    test('does not enable DDC canary features by default', () async {
      var expectedOutputs = {
        'b|lib/b$jsModuleExtension': isNotEmpty,
        'b|lib/b$jsSourceMapExtension': isNotEmpty,
        'b|lib/b$metadataExtension': isNotEmpty,
        'a|lib/a$jsModuleExtension': decodedMatches(isNot(contains('canary'))),
        'a|lib/a$jsSourceMapExtension': isNotEmpty,
        'a|lib/a$metadataExtension': isNotEmpty,
        'a|web/index$jsModuleExtension': isNotEmpty,
        'a|web/index$jsSourceMapExtension': isNotEmpty,
        'a|web/index$metadataExtension': isNotEmpty,
      };
      await testBuilder(
        DevCompilerBuilder(platform: ddcPlatform),
        assets,
        outputs: expectedOutputs,
      );
    });

    test('generates full dill when enabled', () async {
      var expectedOutputs = {
        'b|lib/b$jsModuleExtension': isNotEmpty,
        'b|lib/b$jsSourceMapExtension': isNotEmpty,
        'b|lib/b$metadataExtension': isNotEmpty,
        'b|lib/b$fullKernelExtension': isNotEmpty,
        'a|lib/a$jsModuleExtension': isNotEmpty,
        'a|lib/a$jsSourceMapExtension': isNotEmpty,
        'a|lib/a$metadataExtension': isNotEmpty,
        'a|lib/a$fullKernelExtension': isNotEmpty,
        'a|web/index$jsModuleExtension': isNotEmpty,
        'a|web/index$jsSourceMapExtension': isNotEmpty,
        'a|web/index$metadataExtension': isNotEmpty,
        'a|web/index$fullKernelExtension': isNotEmpty,
      };
      await testBuilder(
        DevCompilerBuilder(platform: ddcPlatform, generateFullDill: true),
        assets,
        outputs: expectedOutputs,
      );
    });

    test('does not generate full dill by default', () async {
      var expectedOutputs = {
        'b|lib/b$jsModuleExtension': isNotEmpty,
        'b|lib/b$jsSourceMapExtension': isNotEmpty,
        'b|lib/b$metadataExtension': isNotEmpty,
        'a|lib/a$jsModuleExtension': isNotEmpty,
        'a|lib/a$jsSourceMapExtension': isNotEmpty,
        'a|lib/a$metadataExtension': isNotEmpty,
        'a|web/index$jsModuleExtension': isNotEmpty,
        'a|web/index$jsSourceMapExtension': isNotEmpty,
        'a|web/index$metadataExtension': isNotEmpty,
      };
      await testBuilder(
        DevCompilerBuilder(platform: ddcPlatform),
        assets,
        outputs: expectedOutputs,
      );
    });

    test('emits debug symbols when enabled', () async {
      var expectedOutputs = {
        'b|lib/b$jsModuleExtension': isNotEmpty,
        'b|lib/b$jsSourceMapExtension': isNotEmpty,
        'b|lib/b$metadataExtension': isNotEmpty,
        'b|lib/b$symbolsExtension': isNotEmpty,
        'a|lib/a$jsModuleExtension': isNotEmpty,
        'a|lib/a$jsSourceMapExtension': isNotEmpty,
        'a|lib/a$metadataExtension': isNotEmpty,
        'a|lib/a$symbolsExtension': isNotEmpty,
        'a|web/index$jsModuleExtension': isNotEmpty,
        'a|web/index$jsSourceMapExtension': isNotEmpty,
        'a|web/index$metadataExtension': isNotEmpty,
        'a|web/index$symbolsExtension': isNotEmpty,
      };
      await testBuilder(
        DevCompilerBuilder(platform: ddcPlatform, emitDebugSymbols: true),
        assets,
        outputs: expectedOutputs,
      );
    });

    test('does not emit debug symbols by default', () async {
      var expectedOutputs = {
        'b|lib/b$jsModuleExtension': isNotEmpty,
        'b|lib/b$jsSourceMapExtension': isNotEmpty,
        'b|lib/b$metadataExtension': isNotEmpty,
        'a|lib/a$jsModuleExtension': isNotEmpty,
        'a|lib/a$jsSourceMapExtension': isNotEmpty,
        'a|lib/a$metadataExtension': isNotEmpty,
        'a|web/index$jsModuleExtension': isNotEmpty,
        'a|web/index$jsSourceMapExtension': isNotEmpty,
        'a|web/index$metadataExtension': isNotEmpty,
      };
      await testBuilder(
        DevCompilerBuilder(platform: ddcPlatform),
        assets,
        outputs: expectedOutputs,
      );
    });

    test('strips scratch paths from metadata', () async {
      var expectedOutputs = {
        'b|lib/b$jsModuleExtension': isNotEmpty,
        'b|lib/b$jsSourceMapExtension': isNotEmpty,
        'b|lib/b$metadataExtension': decodedMatches(isNot(contains('scratch'))),
        'a|lib/a$jsModuleExtension': isNotEmpty,
        'a|lib/a$jsSourceMapExtension': isNotEmpty,
        'a|lib/a$metadataExtension': decodedMatches(isNot(contains('scratch'))),
        'a|web/index$jsModuleExtension': isNotEmpty,
        'a|web/index$jsSourceMapExtension': isNotEmpty,
        'a|web/index$metadataExtension': decodedMatches(
          isNot(contains('scratch')),
        ),
      };
      await testBuilder(
        DevCompilerBuilder(platform: ddcPlatform),
        assets,
        outputs: expectedOutputs,
      );
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
        await testBuilderAndCollectAssets(
          MetaModuleBuilder(ddcPlatform),
          assets,
        );
        await testBuilderAndCollectAssets(
          MetaModuleCleanBuilder(ddcPlatform),
          assets,
        );
        await testBuilderAndCollectAssets(ModuleBuilder(ddcPlatform), assets);
        await testBuilderAndCollectAssets(
          ddcKernelBuilder(const BuilderOptions({})),
          assets,
        );
      });

      test('reports useful messages', () async {
        var expectedOutputs = {
          'a|web/index$jsModuleErrorsExtension': decodedMatches(
            allOf(contains('String'), contains('assigned'), contains('int')),
          ),
        };
        var logs = <LogRecord>[];
        await testBuilder(
          DevCompilerBuilder(platform: ddcPlatform),
          assets,
          outputs: expectedOutputs,
          onLog: logs.add,
        );
        expect(
          logs,
          contains(
            predicate<LogRecord>(
              (record) =>
                  record.level == Level.SEVERE &&
                  record.message.contains('String') &&
                  record.message.contains('assigned') &&
                  record.message.contains('int'),
            ),
          ),
        );
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
        await testBuilderAndCollectAssets(
          MetaModuleBuilder(ddcPlatform),
          assets,
        );
        await testBuilderAndCollectAssets(
          MetaModuleCleanBuilder(ddcPlatform),
          assets,
        );
        await testBuilderAndCollectAssets(ModuleBuilder(ddcPlatform), assets);
      });

      test('reports useful messages', () async {
        var expectedOutputs = {
          'a|web/index$jsModuleErrorsExtension': decodedMatches(
            contains('Unable to find modules for some sources'),
          ),
        };
        var logs = <LogRecord>[];
        await testBuilder(
          DevCompilerBuilder(platform: ddcPlatform),
          assets,
          outputs: expectedOutputs,
          onLog: logs.add,
        );
        expect(
          logs,
          contains(
            predicate<LogRecord>(
              (record) =>
                  record.level == Level.SEVERE &&
                  record.message.contains(
                    'Unable to find modules for some sources',
                  ),
            ),
          ),
        );
      });
    });
  });
}
