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

  for (var soundNullSafety in [true, false]) {
    group('error free project (${soundNullSafety ? 'sound' : 'unsound'})', () {
      setUp(() async {
        var listener = Logger.root.onRecord
            .listen((r) => printOnFailure('$r\n${r.error}\n${r.stackTrace}'));
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
        await testBuilderAndCollectAssets(
            MetaModuleBuilder(ddcPlatform), assets);
        await testBuilderAndCollectAssets(
            MetaModuleCleanBuilder(ddcPlatform), assets);
        await testBuilderAndCollectAssets(ModuleBuilder(ddcPlatform), assets);
        await testBuilderAndCollectAssets(
            ddcKernelBuilder(BuilderOptions({}),
                soundNullSafety: soundNullSafety),
            assets);
      });

      for (var trackUnusedInputs in [true, false]) {
        test(
            'can compile ddc modules under lib and web'
            '${trackUnusedInputs ? ' and track unused inputs' : ''}', () async {
          var expectedOutputs = {
            'b|lib/b${jsModuleExtension(soundNullSafety)}':
                decodedMatches(contains('world')),
            'b|lib/b${jsSourceMapExtension(soundNullSafety)}':
                decodedMatches(contains('b.dart')),
            'b|lib/b${metadataExtension(soundNullSafety)}': isNotEmpty,
            'a|lib/a${jsModuleExtension(soundNullSafety)}':
                decodedMatches(contains('hello')),
            'a|lib/a${jsSourceMapExtension(soundNullSafety)}':
                decodedMatches(contains('a.dart')),
            'a|lib/a${metadataExtension(soundNullSafety)}': isNotEmpty,
            'a|web/index${jsModuleExtension(soundNullSafety)}':
                decodedMatches(contains('main')),
            'a|web/index${jsSourceMapExtension(soundNullSafety)}':
                decodedMatches(contains('index.dart')),
            'a|web/index${metadataExtension(soundNullSafety)}': isNotEmpty,
          };
          var reportedUnused = <AssetId, Iterable<AssetId>>{};

          await testBuilder(
              DevCompilerBuilder(
                  platform: ddcPlatform,
                  useIncrementalCompiler: trackUnusedInputs,
                  trackUnusedInputs: trackUnusedInputs,
                  soundNullSafety: soundNullSafety),
              assets,
              outputs: expectedOutputs,
              reportUnusedAssetsForInput: (input, unused) =>
                  reportedUnused[input] = unused);

          expect(
              reportedUnused[
                  AssetId('a', 'web/index${moduleExtension(ddcPlatform)}')],
              equals(trackUnusedInputs
                  ? [
                      AssetId(
                          'b', 'lib/b${ddcKernelExtension(soundNullSafety)}')
                    ]
                  : null),
              reason: 'Should${trackUnusedInputs ? '' : ' not'} report unused '
                  'transitive deps.');
        });
      }

      test('allows a custom environment', () async {
        var expectedOutputs = {
          'b|lib/b${jsModuleExtension(soundNullSafety)}': isNotEmpty,
          'b|lib/b${jsSourceMapExtension(soundNullSafety)}': isNotEmpty,
          'b|lib/b${metadataExtension(soundNullSafety)}': isNotEmpty,
          'a|lib/a${jsModuleExtension(soundNullSafety)}': isNotEmpty,
          'a|lib/a${jsSourceMapExtension(soundNullSafety)}': isNotEmpty,
          'a|lib/a${metadataExtension(soundNullSafety)}': isNotEmpty,
          'a|web/index${jsModuleExtension(soundNullSafety)}':
              decodedMatches(contains('print("zap")')),
          'a|web/index${jsSourceMapExtension(soundNullSafety)}': isNotEmpty,
          'a|web/index${metadataExtension(soundNullSafety)}': isNotEmpty,
        };
        await testBuilder(
            DevCompilerBuilder(
                platform: ddcPlatform,
                environment: {'foo': 'zap'},
                soundNullSafety: soundNullSafety),
            assets,
            outputs: expectedOutputs);
      });

      test('generates full dill when enabled', () async {
        var expectedOutputs = {
          'b|lib/b${jsModuleExtension(soundNullSafety)}': isNotEmpty,
          'b|lib/b${jsSourceMapExtension(soundNullSafety)}': isNotEmpty,
          'b|lib/b${metadataExtension(soundNullSafety)}': isNotEmpty,
          'b|lib/b${fullKernelExtension(soundNullSafety)}': isNotEmpty,
          'a|lib/a${jsModuleExtension(soundNullSafety)}': isNotEmpty,
          'a|lib/a${jsSourceMapExtension(soundNullSafety)}': isNotEmpty,
          'a|lib/a${metadataExtension(soundNullSafety)}': isNotEmpty,
          'a|lib/a${fullKernelExtension(soundNullSafety)}': isNotEmpty,
          'a|web/index${jsModuleExtension(soundNullSafety)}': isNotEmpty,
          'a|web/index${jsSourceMapExtension(soundNullSafety)}': isNotEmpty,
          'a|web/index${metadataExtension(soundNullSafety)}': isNotEmpty,
          'a|web/index${fullKernelExtension(soundNullSafety)}': isNotEmpty,
        };
        await testBuilder(
            DevCompilerBuilder(
                platform: ddcPlatform,
                generateFullDill: true,
                soundNullSafety: soundNullSafety),
            assets,
            outputs: expectedOutputs);
      });

      test('does not generate full dill by default', () async {
        var expectedOutputs = {
          'b|lib/b${jsModuleExtension(soundNullSafety)}': isNotEmpty,
          'b|lib/b${jsSourceMapExtension(soundNullSafety)}': isNotEmpty,
          'b|lib/b${metadataExtension(soundNullSafety)}': isNotEmpty,
          'a|lib/a${jsModuleExtension(soundNullSafety)}': isNotEmpty,
          'a|lib/a${jsSourceMapExtension(soundNullSafety)}': isNotEmpty,
          'a|lib/a${metadataExtension(soundNullSafety)}': isNotEmpty,
          'a|web/index${jsModuleExtension(soundNullSafety)}': isNotEmpty,
          'a|web/index${jsSourceMapExtension(soundNullSafety)}': isNotEmpty,
          'a|web/index${metadataExtension(soundNullSafety)}': isNotEmpty,
        };
        await testBuilder(
            DevCompilerBuilder(
                platform: ddcPlatform, soundNullSafety: soundNullSafety),
            assets,
            outputs: expectedOutputs);
      });

      test('emits debug symbols when enabled', () async {
        var expectedOutputs = {
          'b|lib/b${jsModuleExtension(soundNullSafety)}': isNotEmpty,
          'b|lib/b${jsSourceMapExtension(soundNullSafety)}': isNotEmpty,
          'b|lib/b${metadataExtension(soundNullSafety)}': isNotEmpty,
          'b|lib/b${symbolsExtension(soundNullSafety)}': isNotEmpty,
          'a|lib/a${jsModuleExtension(soundNullSafety)}': isNotEmpty,
          'a|lib/a${jsSourceMapExtension(soundNullSafety)}': isNotEmpty,
          'a|lib/a${metadataExtension(soundNullSafety)}': isNotEmpty,
          'a|lib/a${symbolsExtension(soundNullSafety)}': isNotEmpty,
          'a|web/index${jsModuleExtension(soundNullSafety)}': isNotEmpty,
          'a|web/index${jsSourceMapExtension(soundNullSafety)}': isNotEmpty,
          'a|web/index${metadataExtension(soundNullSafety)}': isNotEmpty,
          'a|web/index${symbolsExtension(soundNullSafety)}': isNotEmpty,
        };
        await testBuilder(
            DevCompilerBuilder(
                platform: ddcPlatform,
                emitDebugSymbols: true,
                soundNullSafety: soundNullSafety),
            assets,
            outputs: expectedOutputs);
      });

      test('does not emit debug symbols by default', () async {
        var expectedOutputs = {
          'b|lib/b${jsModuleExtension(soundNullSafety)}': isNotEmpty,
          'b|lib/b${jsSourceMapExtension(soundNullSafety)}': isNotEmpty,
          'b|lib/b${metadataExtension(soundNullSafety)}': isNotEmpty,
          'a|lib/a${jsModuleExtension(soundNullSafety)}': isNotEmpty,
          'a|lib/a${jsSourceMapExtension(soundNullSafety)}': isNotEmpty,
          'a|lib/a${metadataExtension(soundNullSafety)}': isNotEmpty,
          'a|web/index${jsModuleExtension(soundNullSafety)}': isNotEmpty,
          'a|web/index${jsSourceMapExtension(soundNullSafety)}': isNotEmpty,
          'a|web/index${metadataExtension(soundNullSafety)}': isNotEmpty,
        };
        await testBuilder(
            DevCompilerBuilder(
                platform: ddcPlatform, soundNullSafety: soundNullSafety),
            assets,
            outputs: expectedOutputs);
      });

      test('strips scratch paths from metadata', () async {
        var expectedOutputs = {
          'b|lib/b${jsModuleExtension(soundNullSafety)}': isNotEmpty,
          'b|lib/b${jsSourceMapExtension(soundNullSafety)}': isNotEmpty,
          'b|lib/b${metadataExtension(soundNullSafety)}':
              decodedMatches(isNot(contains('scratch'))),
          'a|lib/a${jsModuleExtension(soundNullSafety)}': isNotEmpty,
          'a|lib/a${jsSourceMapExtension(soundNullSafety)}': isNotEmpty,
          'a|lib/a${metadataExtension(soundNullSafety)}':
              decodedMatches(isNot(contains('scratch'))),
          'a|web/index${jsModuleExtension(soundNullSafety)}': isNotEmpty,
          'a|web/index${jsSourceMapExtension(soundNullSafety)}': isNotEmpty,
          'a|web/index${metadataExtension(soundNullSafety)}':
              decodedMatches(isNot(contains('scratch'))),
        };
        await testBuilder(
            DevCompilerBuilder(
                platform: ddcPlatform, soundNullSafety: soundNullSafety),
            assets,
            outputs: expectedOutputs);
      });
    });
  }

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
            MetaModuleBuilder(ddcPlatform), assets);
        await testBuilderAndCollectAssets(
            MetaModuleCleanBuilder(ddcPlatform), assets);
        await testBuilderAndCollectAssets(ModuleBuilder(ddcPlatform), assets);
        await testBuilderAndCollectAssets(
            ddcKernelBuilder(BuilderOptions({})), assets);
      });

      test('reports useful messages', () async {
        var expectedOutputs = {
          'a|web/index${jsModuleErrorsExtension(false)}': decodedMatches(
              allOf(contains('String'), contains('assigned'), contains('int'))),
        };
        var logs = <LogRecord>[];
        await testBuilder(DevCompilerBuilder(platform: ddcPlatform), assets,
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
          'a|web/index.dart': "import 'package:a/a.dart'",
        };

        // Set up all the other required inputs for this test.
        await testBuilderAndCollectAssets(const ModuleLibraryBuilder(), assets);
        await testBuilderAndCollectAssets(
            MetaModuleBuilder(ddcPlatform), assets);
        await testBuilderAndCollectAssets(
            MetaModuleCleanBuilder(ddcPlatform), assets);
        await testBuilderAndCollectAssets(ModuleBuilder(ddcPlatform), assets);
      });

      test('reports useful messages', () async {
        var expectedOutputs = {
          'a|web/index${jsModuleErrorsExtension(false)}': decodedMatches(
              contains('Unable to find modules for some sources')),
        };
        var logs = <LogRecord>[];
        await testBuilder(DevCompilerBuilder(platform: ddcPlatform), assets,
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
