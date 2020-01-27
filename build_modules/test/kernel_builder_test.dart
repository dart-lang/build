// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'package:build_modules/build_modules.dart';

import 'util.dart';

void main() {
  Map<String, dynamic> assets;
  final platform = DartPlatform.register('ddc', ['dart:html']);
  final kernelOutputExtension = '.test.dill';

  group('basic project', () {
    setUp(() async {
      assets = {
        'b|lib/b.dart': '''final world = 'world';''',
        'a|lib/a.dart': r'''
        import 'package:b/b.dart';
        final helloWorld = 'hello $world';
      ''',
        'a|web/index.dart': r'''
        import "package:a/a.dart";

        main() {
          print(helloWorld);
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

    for (var trackUnusedInputs in [true, false]) {
      test(
          'can output kernel summaries for modules under lib and web'
          '${trackUnusedInputs ? ' and track unused inputs' : ''}', () async {
        var builder = KernelBuilder(
          platform: platform,
          outputExtension: kernelOutputExtension,
          summaryOnly: true,
          sdkKernelPath: p.url.join('lib', '_internal', 'ddc_sdk.dill'),
          useIncrementalCompiler: trackUnusedInputs,
          trackUnusedInputs: trackUnusedInputs,
        );
        // We need to compile package:b first - so its kernel file is
        // available.
        var expectedOutputs = <String, Matcher>{
          'b|lib/b$kernelOutputExtension':
              containsAllInOrder(utf8.encode('package:b/b.dart')),
        };

        await testBuilderAndCollectAssets(builder, assets,
            outputs: expectedOutputs,
            generateFor: {'b|lib/b${moduleExtension(platform)}'});

        // Next, compile package:a
        expectedOutputs = {
          'a|lib/a$kernelOutputExtension':
              containsAllInOrder(utf8.encode('package:a/a.dart')),
        };

        await testBuilderAndCollectAssets(builder, assets,
            outputs: expectedOutputs,
            generateFor: {
              'a|lib/a${moduleExtension(platform)}',
            });

        expectedOutputs = {
          'a|web/index$kernelOutputExtension':
              containsAllInOrder(utf8.encode('web/index.dart')),
        };

        // And finally compile a|web/index.dart
        var reportedUnused = <AssetId, Iterable<AssetId>>{};
        await testBuilder(builder, assets,
            outputs: expectedOutputs,
            reportUnusedAssetsForInput: (input, unused) =>
                reportedUnused[input] = unused,
            generateFor: {'a|web/index${moduleExtension(platform)}'});
        expect(
            reportedUnused[
                AssetId('a', 'web/index${moduleExtension(platform)}')],
            equals(trackUnusedInputs
                ? [AssetId('b', 'lib/b$kernelOutputExtension')]
                : null),
            reason: 'Should${trackUnusedInputs ? '' : ' not'} report unused '
                'transitive deps.');
      });
    }
  });

  group('kernel outlines with missing imports', () {
    setUp(() async {
      assets = {
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
          KernelBuilder(
            platform: platform,
            outputExtension: kernelOutputExtension,
            summaryOnly: true,
            sdkKernelPath: p.url.join('lib', '_internal', 'ddc_sdk.dill'),
          ),
          assets);
    });

    test('print an error if there are any missing transitive modules',
        () async {
      var expectedOutputs = <String, Matcher>{};
      var logs = <LogRecord>[];
      await testBuilder(
          KernelBuilder(
            platform: platform,
            outputExtension: kernelOutputExtension,
            summaryOnly: true,
            sdkKernelPath: p.url.join('lib', '_internal', 'ddc_sdk.dill'),
          ),
          assets,
          outputs: expectedOutputs,
          onLog: logs.add);
      expect(
          logs,
          contains(predicate<LogRecord>((record) =>
              record.level == Level.SEVERE &&
              record.message
                  .contains('Unable to find modules for some sources'))));
    });
  });
}
