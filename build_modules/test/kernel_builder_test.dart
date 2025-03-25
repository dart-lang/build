// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:build/build.dart';
import 'package:build_modules/build_modules.dart';
import 'package:build_test/build_test.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  final platform = DartPlatform.register('ddc', ['dart:html']);
  final kernelOutputExtension = '.test.dill';

  group('basic project', () {
    final startingAssets = {
      'a|web/index.dart': r'''
        import "package:b/b.dart";

        main() {
          print(helloWorld);
        }
      ''',
      'b|lib/b.dart': r'''
        import 'package:c/c.dart';
        final helloWorld = 'hello $world';
      ''',
      'c|lib/c.dart': '''final world = 'world';''',
    };
    final startingBuilders = [
      const ModuleLibraryBuilder(),
      MetaModuleBuilder(platform),
      MetaModuleCleanBuilder(platform),
      ModuleBuilder(platform),
    ];
    final startingExpectedOutputs = {
      'a|lib/.ddc.meta_module.clean': isNotNull,
      'a|lib/.ddc.meta_module.raw': isNotNull,
      'a|web/index.ddc.module': isNotNull,
      'a|web/index.module.library': isNotNull,
      'b|lib/.ddc.meta_module.clean': isNotNull,
      'b|lib/.ddc.meta_module.raw': isNotNull,
      'b|lib/b.ddc.module': isNotNull,
      'b|lib/b.module.library': isNotNull,
      'c|lib/.ddc.meta_module.clean': isNotNull,
      'c|lib/.ddc.meta_module.raw': isNotNull,
      'c|lib/c.ddc.module': isNotNull,
      'c|lib/c.module.library': isNotNull,
    };
    test('base build', () async {
      await testBuilders(
        startingBuilders,
        startingAssets,
        outputs: startingExpectedOutputs,
      );
    });

    for (var trackUnusedInputs in [true, false]) {
      test('can output kernel summaries for modules under lib and web '
          '${trackUnusedInputs ? 'tracking' : 'not tracking'} '
          'unused inputs', () async {
        var builder = KernelBuilder(
          platform: platform,
          outputExtension: kernelOutputExtension,
          summaryOnly: true,
          sdkKernelPath: p.url.join('lib', '_internal', 'ddc_outline.dill'),
          useIncrementalCompiler: trackUnusedInputs,
          trackUnusedInputs: trackUnusedInputs,
        );

        var expectedOutputs = Map.of(startingExpectedOutputs)..addAll({
          'a|web/index$kernelOutputExtension': containsAllInOrder(
            utf8.encode('web/index.dart'),
          ),
          'b|lib/b$kernelOutputExtension': containsAllInOrder(
            utf8.encode('package:b/b.dart'),
          ),
          'c|lib/c$kernelOutputExtension': containsAllInOrder(
            utf8.encode('package:c/c.dart'),
          ),
        });

        var reportedUnused = <AssetId, Iterable<AssetId>>{};
        await testBuilders(
          [...startingBuilders, builder],
          startingAssets,
          outputs: expectedOutputs,
          reportUnusedAssetsForInput: (input, unused) {
            reportedUnused[input] = unused;
          },
        );

        expect(
          reportedUnused[AssetId('a', 'web/index${moduleExtension(platform)}')],
          equals(
            trackUnusedInputs
                ? [AssetId('c', 'lib/c$kernelOutputExtension')]
                : null,
          ),
          reason:
              'Should${trackUnusedInputs ? '' : ' not'} report unused '
              'transitive deps.',
        );
      });
    }
  });

  group('kernel outlines with missing imports', () {
    final startingAssets = {
      'a|web/index.dart': 'import "package:a/a.dart";',
      'a|lib/a.dart': 'import "package:b/b.dart";',
    };
    final startingBuilders = [
      const ModuleLibraryBuilder(),
      MetaModuleBuilder(platform),
      MetaModuleCleanBuilder(platform),
      ModuleBuilder(platform),
      KernelBuilder(
        platform: platform,
        outputExtension: kernelOutputExtension,
        summaryOnly: true,
        sdkKernelPath: p.url.join('lib', '_internal', 'ddc_sdk.dill'),
      ),
    ];
    final startingExpectedOutputs = <String, Object>{
      'a|lib/.ddc.meta_module.clean': isNotNull,
      'a|lib/.ddc.meta_module.raw': isNotNull,
      'a|lib/a.ddc.module': isNotNull,
      'a|lib/a.module.library': isNotNull,
      'a|web/index.ddc.module': isNotNull,
      'a|web/index.module.library': isNotNull,
    };

    test('base build', () async {
      await testBuilders(
        startingBuilders,
        startingAssets,
        rootPackage: 'a',
        outputs: startingExpectedOutputs,
      );
    });

    test(
      'print an error if there are any missing transitive modules',
      () async {
        var logs = <LogRecord>[];
        await testBuilders(
          startingBuilders,
          startingAssets,
          outputs: startingExpectedOutputs,
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
      },
    );
  });
}
