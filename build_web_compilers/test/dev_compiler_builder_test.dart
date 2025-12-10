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

const ddcLibraryBundle = false;

final builderOptions = const BuilderOptions({
  'track-unused-inputs': false,
  'ddc-library-bundle': ddcLibraryBundle,
});

void main() {
  initializePlatforms();

  group('error free project', () {
    final startingAssets = {
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
      'b|lib/b.dart': '''
        // @dart=2.12
        final world = 'world';''',
    };
    final startingBuilders = [
      const ModuleLibraryBuilder(),
      MetaModuleBuilder(ddcPlatform),
      MetaModuleCleanBuilder(ddcPlatform),
      ModuleBuilder(ddcPlatform),
      ddcKernelBuilder(builderOptions),
    ];
    final startingExpectedOutputs = <String, Object>{
      'a|lib/.ddc.meta_module.clean': isNotNull,
      'a|lib/.ddc.meta_module.raw': isNotNull,
      'a|lib/a.ddc.dill': isNotNull,
      'a|lib/a.ddc.module': isNotNull,
      'a|lib/a.module.library': isNotNull,
      'a|web/index.ddc.dill': isNotNull,
      'a|web/index.ddc.module': isNotNull,
      'a|web/index.module.library': isNotNull,
      'b|lib/.ddc.meta_module.clean': isNotNull,
      'b|lib/.ddc.meta_module.raw': isNotNull,
      'b|lib/b.ddc.dill': isNotNull,
      'b|lib/b.ddc.module': isNotNull,
      'b|lib/b.module.library': isNotNull,
    };

    setUp(() async {
      final listener = Logger.root.onRecord.listen(
        (r) => printOnFailure('$r\n${r.error}\n${r.stackTrace}'),
      );
      addTearDown(listener.cancel);
    });

    test('base build', () async {
      await testBuilders(
        startingBuilders,
        startingAssets,
        outputs: startingExpectedOutputs,
      );
    });

    for (final trackUnusedInputs in [true, false]) {
      test('can compile ddc modules under lib and web and '
          '${trackUnusedInputs ? 'track' : 'not track'} '
          'unused inputs', () async {
        final builder = DevCompilerBuilder(
          platform: ddcPlatform,
          useIncrementalCompiler: trackUnusedInputs,
          trackUnusedInputs: trackUnusedInputs,
          ddcLibraryBundle: ddcLibraryBundle,
        );

        final expectedOutputs = Map.of(startingExpectedOutputs)..addAll({
          'a|lib/a$jsModuleExtension': decodedMatches(contains('hello')),
          'a|lib/a$jsSourceMapExtension': decodedMatches(contains('a.dart')),
          'a|lib/a$metadataExtension': isNotNull,
          'a|web/index$jsModuleExtension': decodedMatches(contains('main')),
          'a|web/index$jsSourceMapExtension': decodedMatches(
            contains('index.dart'),
          ),
          'a|web/index$metadataExtension': isNotNull,
          'b|lib/b$jsModuleExtension': decodedMatches(contains('world')),
          'b|lib/b$jsSourceMapExtension': decodedMatches(contains('b.dart')),
          'b|lib/b$metadataExtension': isNotNull,
        });

        final reportedUnused = <AssetId, Iterable<AssetId>>{};
        await testBuilders(
          [...startingBuilders, builder],
          startingAssets,
          outputs: expectedOutputs,
          reportUnusedAssetsForInput: (input, unused) {
            reportedUnused[input] = unused;
          },
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
      final builder = DevCompilerBuilder(
        platform: ddcPlatform,
        environment: {'foo': 'zap'},
        ddcLibraryBundle: ddcLibraryBundle,
      );
      final expectedOutputs = Map.of(startingExpectedOutputs)..addAll({
        'a|lib/a$jsModuleExtension': isNotNull,
        'a|lib/a$jsSourceMapExtension': isNotNull,
        'a|lib/a$metadataExtension': isNotNull,
        'a|web/index$jsModuleExtension': decodedMatches(
          contains('print("zap")'),
        ),
        'a|web/index$jsSourceMapExtension': isNotNull,
        'a|web/index$metadataExtension': isNotNull,
        'b|lib/b$jsModuleExtension': isNotNull,
        'b|lib/b$jsSourceMapExtension': isNotNull,
        'b|lib/b$metadataExtension': isNotNull,
      });
      await testBuilders(
        [...startingBuilders, builder],
        startingAssets,
        outputs: expectedOutputs,
      );
    });

    test('can enable DDC canary features', () async {
      final builder = DevCompilerBuilder(
        platform: ddcPlatform,
        canaryFeatures: true,
        ddcLibraryBundle: ddcLibraryBundle,
      );
      final expectedOutputs = Map.of(startingExpectedOutputs)..addAll({
        'a|lib/a$jsModuleExtension': decodedMatches(contains('canary')),
        'a|lib/a$jsSourceMapExtension': isNotNull,
        'a|lib/a$metadataExtension': isNotNull,
        'a|web/index$jsModuleExtension': isNotNull,
        'a|web/index$jsSourceMapExtension': isNotNull,
        'a|web/index$metadataExtension': isNotNull,
        'b|lib/b$jsModuleExtension': isNotNull,
        'b|lib/b$jsSourceMapExtension': isNotNull,
        'b|lib/b$metadataExtension': isNotNull,
      });
      await testBuilders(
        [...startingBuilders, builder],
        startingAssets,
        outputs: expectedOutputs,
      );
    });

    test('does not enable DDC canary features by default', () async {
      final builder = DevCompilerBuilder(
        platform: ddcPlatform,
        ddcLibraryBundle: ddcLibraryBundle,
      );
      final expectedOutputs = Map.of(startingExpectedOutputs)..addAll({
        'a|lib/a$jsModuleExtension': decodedMatches(isNot(contains('canary'))),
        'a|lib/a$jsSourceMapExtension': isNotNull,
        'a|lib/a$metadataExtension': isNotNull,
        'a|web/index$jsModuleExtension': isNotNull,
        'a|web/index$jsSourceMapExtension': isNotNull,
        'a|web/index$metadataExtension': isNotNull,
        'b|lib/b$jsModuleExtension': isNotNull,
        'b|lib/b$jsSourceMapExtension': isNotNull,
        'b|lib/b$metadataExtension': isNotNull,
      });
      await testBuilders(
        [...startingBuilders, builder],
        startingAssets,
        outputs: expectedOutputs,
      );
    });

    test('generates full dill when enabled', () async {
      final builder = DevCompilerBuilder(
        platform: ddcPlatform,
        generateFullDill: true,
        ddcLibraryBundle: ddcLibraryBundle,
      );
      final expectedOutputs = Map.of(startingExpectedOutputs)..addAll({
        'a|lib/a$fullKernelExtension': isNotNull,
        'a|lib/a$jsModuleExtension': isNotNull,
        'a|lib/a$jsSourceMapExtension': isNotNull,
        'a|lib/a$metadataExtension': isNotNull,
        'a|web/index$fullKernelExtension': isNotNull,
        'a|web/index$jsModuleExtension': isNotNull,
        'a|web/index$jsSourceMapExtension': isNotNull,
        'a|web/index$metadataExtension': isNotNull,
        'b|lib/b$fullKernelExtension': isNotNull,
        'b|lib/b$jsModuleExtension': isNotNull,
        'b|lib/b$jsSourceMapExtension': isNotNull,
        'b|lib/b$metadataExtension': isNotNull,
      });
      await testBuilders(
        [...startingBuilders, builder],
        startingAssets,
        outputs: expectedOutputs,
      );
    });

    test('does not generate full dill by default', () async {
      final builder = DevCompilerBuilder(
        platform: ddcPlatform,
        ddcLibraryBundle: ddcLibraryBundle,
      );
      final expectedOutputs = Map.of(startingExpectedOutputs)..addAll({
        'a|lib/a$jsModuleExtension': isNotNull,
        'a|lib/a$jsSourceMapExtension': isNotNull,
        'a|lib/a$metadataExtension': isNotNull,
        'a|web/index$jsModuleExtension': isNotNull,
        'a|web/index$jsSourceMapExtension': isNotNull,
        'a|web/index$metadataExtension': isNotNull,
        'b|lib/b$jsModuleExtension': isNotNull,
        'b|lib/b$jsSourceMapExtension': isNotNull,
        'b|lib/b$metadataExtension': isNotNull,
      });
      await testBuilders(
        [...startingBuilders, builder],
        startingAssets,
        outputs: expectedOutputs,
      );
    });

    test('emits debug symbols when enabled', () async {
      final builder = DevCompilerBuilder(
        platform: ddcPlatform,
        emitDebugSymbols: true,
        ddcLibraryBundle: ddcLibraryBundle,
      );
      final expectedOutputs = Map.of(startingExpectedOutputs)..addAll({
        'a|lib/a$jsModuleExtension': isNotNull,
        'a|lib/a$jsSourceMapExtension': isNotNull,
        'a|lib/a$metadataExtension': isNotNull,
        'a|lib/a$symbolsExtension': isNotNull,
        'a|web/index$jsModuleExtension': isNotNull,
        'a|web/index$jsSourceMapExtension': isNotNull,
        'a|web/index$metadataExtension': isNotNull,
        'a|web/index$symbolsExtension': isNotNull,
        'b|lib/b$jsModuleExtension': isNotNull,
        'b|lib/b$jsSourceMapExtension': isNotNull,
        'b|lib/b$metadataExtension': isNotNull,
        'b|lib/b$symbolsExtension': isNotNull,
      });
      await testBuilders(
        [...startingBuilders, builder],
        startingAssets,
        outputs: expectedOutputs,
      );
    });

    test('does not emit debug symbols by default', () async {
      final builder = DevCompilerBuilder(
        platform: ddcPlatform,
        ddcLibraryBundle: ddcLibraryBundle,
      );
      final expectedOutputs = Map.of(startingExpectedOutputs)..addAll({
        'b|lib/b$jsModuleExtension': isNotNull,
        'b|lib/b$jsSourceMapExtension': isNotNull,
        'b|lib/b$metadataExtension': isNotNull,
        'a|lib/a$jsModuleExtension': isNotNull,
        'a|lib/a$jsSourceMapExtension': isNotNull,
        'a|lib/a$metadataExtension': isNotNull,
        'a|web/index$jsModuleExtension': isNotNull,
        'a|web/index$jsSourceMapExtension': isNotNull,
        'a|web/index$metadataExtension': isNotNull,
      });
      await testBuilders(
        [...startingBuilders, builder],
        startingAssets,
        outputs: expectedOutputs,
      );
    });

    test('strips scratch paths from metadata', () async {
      final builder = DevCompilerBuilder(
        platform: ddcPlatform,
        ddcLibraryBundle: ddcLibraryBundle,
      );
      final expectedOutputs = Map.of(startingExpectedOutputs)..addAll({
        'a|lib/a$jsModuleExtension': isNotNull,
        'a|lib/a$jsSourceMapExtension': isNotNull,
        'a|lib/a$metadataExtension': decodedMatches(isNot(contains('scratch'))),
        'a|web/index$jsModuleExtension': isNotNull,
        'a|web/index$jsSourceMapExtension': isNotNull,
        'a|web/index$metadataExtension': decodedMatches(
          isNot(contains('scratch')),
        ),
        'b|lib/b$jsModuleExtension': isNotNull,
        'b|lib/b$jsSourceMapExtension': isNotNull,
        'b|lib/b$metadataExtension': decodedMatches(isNot(contains('scratch'))),
      });
      await testBuilders(
        [...startingBuilders, builder],
        startingAssets,
        outputs: expectedOutputs,
      );
    });
  });

  group('projects with errors due to', () {
    group('invalid assignements', () {
      test('reports useful messages', () async {
        final assets = {
          'a|web/index.dart': 'int x = "hello";',
          'build_modules|lib/src/analysis_options.default.yaml': '',
        };
        final expectedOutputs = {
          'a|lib/.ddc.meta_module.clean': isNotNull,
          'a|lib/.ddc.meta_module.raw': isNotNull,
          'a|web/index.ddc.dill': isNotNull,
          'a|web/index.ddc.module': isNotNull,
          'a|web/index$jsModuleErrorsExtension': decodedMatches(
            allOf(contains('String'), contains('assigned'), contains('int')),
          ),
          'a|web/index.module.library': isNotNull,
          'build_modules|lib/.ddc.meta_module.clean': isNotNull,
          'build_modules|lib/.ddc.meta_module.raw': isNotNull,
        };
        final logs = <LogRecord>[];
        await testBuilders(
          [
            const ModuleLibraryBuilder(),
            MetaModuleBuilder(ddcPlatform),
            MetaModuleCleanBuilder(ddcPlatform),
            ModuleBuilder(ddcPlatform),
            ddcKernelBuilder(builderOptions),
            DevCompilerBuilder(
              platform: ddcPlatform,
              ddcLibraryBundle: ddcLibraryBundle,
            ),
          ],
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
      test('reports useful messages', () async {
        final assets = {
          'a|web/index.dart': "import 'package:a/a.dart'",
          'build_modules|lib/src/analysis_options.default.yaml': '',
        };
        final expectedOutputs = {
          'a|lib/.ddc.meta_module.clean': isNotNull,
          'a|lib/.ddc.meta_module.raw': isNotNull,
          'a|web/index$jsModuleErrorsExtension': decodedMatches(
            contains('Unable to find modules for some sources'),
          ),
          'a|web/index.ddc.module': isNotNull,
          'a|web/index.module.library': isNotNull,
          'build_modules|lib/.ddc.meta_module.clean': isNotNull,
          'build_modules|lib/.ddc.meta_module.raw': isNotNull,
        };
        final logs = <LogRecord>[];
        await testBuilders(
          [
            const ModuleLibraryBuilder(),
            MetaModuleBuilder(ddcPlatform),
            MetaModuleCleanBuilder(ddcPlatform),
            ModuleBuilder(ddcPlatform),
            ddcKernelBuilder(builderOptions),
            DevCompilerBuilder(
              platform: ddcPlatform,
              ddcLibraryBundle: ddcLibraryBundle,
            ),
          ],
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
