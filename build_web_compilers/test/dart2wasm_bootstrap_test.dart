// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:build_modules/build_modules.dart';
import 'package:build_test/build_test.dart';
import 'package:build_web_compilers/build_web_compilers.dart';
import 'package:test/test.dart';

void main() {
  initializePlatforms();
  final startingAssets = {
    'a|web/index.dart': '''
        void main() {
          print('Hello world!');
        }
      ''',
  };
  final startingBuilders = [
    const ModuleLibraryBuilder(),
    MetaModuleBuilder(dart2jsPlatform),
    MetaModuleCleanBuilder(dart2jsPlatform),
    ModuleBuilder(dart2jsPlatform),
    MetaModuleBuilder(dart2wasmPlatform),
    MetaModuleCleanBuilder(dart2wasmPlatform),
    ModuleBuilder(dart2wasmPlatform),
  ];
  final startingExpectedOutputs = <String, Object>{
    'a|lib/.dart2js.meta_module.clean': isNotNull,
    'a|lib/.dart2js.meta_module.raw': isNotNull,
    'a|lib/.dart2wasm.meta_module.clean': isNotNull,
    'a|lib/.dart2wasm.meta_module.raw': isNotNull,
    'a|web/index.dart2js.module': isNotNull,
    'a|web/index.dart2wasm.module': isNotNull,
    'a|web/index.module.library': isNotNull,
  };

  test('base build', () async {
    await testBuilders(
      startingBuilders,
      startingAssets,
      outputs: startingExpectedOutputs,
    );
  });

  group('generates loader script', () {
    test('with old compiler option', () async {
      final builder = WebEntrypointBuilder.fromOptions(
        const BuilderOptions({'compiler': 'dart2wasm'}),
      );

      final expectedOutputs = Map.of(startingExpectedOutputs)..addAll({
        'a|web/index.dart.js': decodedMatches(contains('compileStreaming')),
        'a|web/index.mjs': isNotNull,
        'a|web/index.wasm.map': isNotNull,
        'a|web/index.wasm': isNotNull,
      });

      await testBuilders(
        [...startingBuilders, builder],
        startingAssets,
        outputs: expectedOutputs,
      );
    });

    test('when using both dart2wasm and dart2js', () async {
      final builder = WebEntrypointBuilder.fromOptions(
        const BuilderOptions({
          'compilers': {
            'dart2js': <String, Object?>{},
            'dart2wasm': <String, Object?>{},
          },
        }),
      );
      final expectedOutputs = Map.of(startingExpectedOutputs)..addAll({
        'a|web/index.dart.js': decodedMatches(
          stringContainsInOrder([
            'if',
            // Depending on whether dart2wasm emitted a .support.js file,
            // this check either comes from dart2wasm or from our own script
            // doing its own feature detection as a fallback. Which one is
            // used depends on the SDK version, we can only assume that the
            // check is guaranteed to include WebAssembly.validate to check
            // for WASM features.
            'WebAssembly.validate',
            '{',
            'compileStreaming',
            '} else {',
            'scriptTag.src = relativeURL("./index.dart2js.js");',
          ]),
        ),
        'a|web/index.dart.js.tar.gz': isNotNull,
        'a|web/index.dart2js.js': decodedMatches(contains('Hello world!')),
        'a|web/index.dart2js.js.map': isNotNull,
        'a|web/index.mjs': isNotNull,
        'a|web/index.wasm.map': isNotNull,
        'a|web/index.wasm': isNotNull,
      });

      await testBuilders(
        [...startingBuilders, builder],
        startingAssets,
        outputs: expectedOutputs,
      );
    });

    test('loader script supports web workers', () async {
      final builder = WebEntrypointBuilder.fromOptions(
        const BuilderOptions({
          'compilers': {
            'dart2js': <String, Object?>{},
            'dart2wasm': <String, Object?>{},
          },
        }),
      );
      final expectedOutputs = Map.of(startingExpectedOutputs)..addAll({
        'a|web/index.dart.js': decodedMatches(
          allOf([
            // Worker detection.
            contains("const isWorker = typeof document === 'undefined'"),
            // thisScript guarded for worker context.
            contains(
              'const thisScript = isWorker ? undefined'
              ' : document.currentScript',
            ),
            // relativeURL has worker branch using self.location.href.
            contains('new URL(ref, self.location.href)'),
            // forceJS is extracted from script src params as well
            // as location search.
            contains(
              'new URL(thisScript.src).searchParams'
              ".get('force_js')",
            ),
            contains(
              'new URLSearchParams(self.location.search)'
              ".get('force_js')",
            ),
            // JS fallback uses importScripts in worker context.
            contains('importScripts(relativeURL('),
            // Wasm module import uses relativeURL.
            contains('await import(relativeURL('),
          ]),
        ),
        'a|web/index.dart.js.tar.gz': isNotNull,
        'a|web/index.dart2js.js': isNotNull,
        'a|web/index.dart2js.js.map': isNotNull,
        'a|web/index.mjs': isNotNull,
        'a|web/index.wasm.map': isNotNull,
        'a|web/index.wasm': isNotNull,
      });

      await testBuilders(
        [...startingBuilders, builder],
        startingAssets,
        outputs: expectedOutputs,
      );
    });
  });

  test('can disable generation of loader script', () async {
    final expectedOutputs = Map.of(startingExpectedOutputs)..addAll({
      'a|web/index.dart.js.tar.gz': isNotNull,
      'a|web/index.dart2js.js': decodedMatches(contains('Hello world!')),
      'a|web/index.dart2js.js.map': isNotNull,
      'a|web/index.mjs': isNotNull,
      'a|web/index.wasm.map': isNotNull,
      'a|web/index.wasm': isNotNull,
    });

    final builder = WebEntrypointBuilder.fromOptions(
      const BuilderOptions({
        'compilers': {
          'dart2js': <String, Object?>{},
          'dart2wasm': <String, Object?>{},
        },
        'loader': null,
      }),
    );

    await testBuilders(
      [...startingBuilders, builder],
      startingAssets,
      outputs: expectedOutputs,
    );
  });
}
