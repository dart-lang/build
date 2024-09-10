// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:build_modules/build_modules.dart';
import 'package:build_test/build_test.dart';
import 'package:build_web_compilers/build_web_compilers.dart';
import 'package:test/test.dart';

import 'util.dart';

void main() {
  late Map<String, Object> assets;

  setUp(() async {
    assets = {
      'a|web/index.dart': '''
        void main() {
          print('Hello world!');
        }
      ''',
    };

    // Set up all the other required inputs for this test.
    await testBuilderAndCollectAssets(const ModuleLibraryBuilder(), assets);
    for (final platform in [dart2jsPlatform, dart2wasmPlatform]) {
      await testBuilderAndCollectAssets(MetaModuleBuilder(platform), assets);
      await testBuilderAndCollectAssets(
          MetaModuleCleanBuilder(platform), assets);
      await testBuilderAndCollectAssets(ModuleBuilder(platform), assets);
    }
  });

  group('generates loader script', () {
    test('with old compiler option', () async {
      await testBuilder(
        WebEntrypointBuilder.fromOptions(
            const BuilderOptions({'compiler': 'dart2wasm'})),
        assets,
        outputs: {
          'a|web/index.mjs': anything,
          'a|web/index.wasm': anything,
          'a|web/index.dart.js':
              decodedMatches(contains('WebAssembly.compileStreaming')),
        },
      );
    });

    test('when using both dart2wasm and dart2js', () async {
      await testBuilder(
        WebEntrypointBuilder.fromOptions(
          const BuilderOptions(
            {
              'compilers': {
                'dart2js': <String, Object?>{},
                'dart2wasm': <String, Object?>{},
              },
            },
          ),
        ),
        assets,
        outputs: {
          'a|web/index.mjs': anything,
          'a|web/index.wasm': anything,
          'a|web/index.dart2js.js': decodedMatches(contains('Hello world!')),
          'a|web/index.dart.js': decodedMatches(
            stringContainsInOrder(
              [
                'if (supportsWasmGC())',
                'WebAssembly.compileStreaming',
                'else',
                'scriptTag.src = resolveUrlWithSegments("./index.dart2js.js");'
              ],
            ),
          ),
        },
      );
    });
  });

  test('can disable generation of loader script', () async {
    await testBuilder(
      WebEntrypointBuilder.fromOptions(
        const BuilderOptions(
          {
            'compilers': {
              'dart2js': <String, Object?>{},
              'dart2wasm': <String, Object?>{},
            },
            'loader': null,
          },
        ),
      ),
      assets,
      outputs: {
        'a|web/index.mjs': anything,
        'a|web/index.wasm': anything,
        'a|web/index.dart2js.js': decodedMatches(contains('Hello world!')),
      },
    );
  });
}
