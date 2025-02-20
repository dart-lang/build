// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:build_web_compilers/src/web_entrypoint_builder.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void main() {
  test('uses ddc by default', () {
    final options = EntrypointBuilderOptions.fromOptions(
      const BuilderOptions({}),
    );
    expect(options.compilers, [
      isA<EnabledEntrypointCompiler>()
          .having((e) => e.compiler, 'compiler', WebCompiler.DartDevc)
          .having((e) => e.compilerArguments, 'compilerArguments', isEmpty)
          .having((e) => e.extension, 'extension', '.dart.js'),
    ]);
  });

  test('parses old dart2js options', () {
    final options = EntrypointBuilderOptions.fromOptions(
      const BuilderOptions({
        'compiler': 'dart2js',
        'dart2js_args': ['-O4'],
      }),
    );

    expect(options.nativeNullAssertions, isNull);
    expect(options.loaderExtension, isNull);
    expect(options.compilers, [
      isA<EnabledEntrypointCompiler>()
          .having((e) => e.compiler, 'compiler', WebCompiler.Dart2Js)
          .having((e) => e.compilerArguments, 'compilerArguments', ['-O4'])
          .having((e) => e.extension, 'extension', '.dart.js'),
    ]);
  });

  test('parses old ddc options', () {
    final options = EntrypointBuilderOptions.fromOptions(
      const BuilderOptions({
        'compiler': 'dartdevc',
        'dart2js_args': ['-O4'],
      }),
    );

    expect(options.nativeNullAssertions, isNull);
    expect(options.loaderExtension, isNull);
    expect(options.compilers, [
      isA<EnabledEntrypointCompiler>()
          .having((e) => e.compiler, 'compiler', WebCompiler.DartDevc)
          .having((e) => e.compilerArguments, 'compilerArguments', isEmpty)
          .having((e) => e.extension, 'extension', '.dart.js'),
    ]);
  });

  test('parses old dart2wasm options', () {
    final options = EntrypointBuilderOptions.fromOptions(
      const BuilderOptions({
        'compiler': 'dart2wasm',
        'dart2wasm_args': ['-O4'],
      }),
    );

    expect(options.nativeNullAssertions, isNull);
    expect(options.loaderExtension, '.dart.js');
    expect(options.compilers, [
      isA<EnabledEntrypointCompiler>()
          .having((e) => e.compiler, 'compiler', WebCompiler.Dart2Wasm)
          .having((e) => e.compilerArguments, 'compilerArguments', ['-O4'])
          .having((e) => e.extension, 'extension', '.mjs'),
    ]);
  });

  test('can enable multiple compilers', () {
    final yamlOptions =
        loadYaml('''
compilers:
  dart2js:
    args:
      - "-O4"
  dart2wasm:
    extension: .custom_extension.js
    args:
      - "-O3"
loader: .dart.js
''')
            as Map;

    final options = EntrypointBuilderOptions.fromOptions(
      BuilderOptions(yamlOptions.cast()),
    );

    expect(options.nativeNullAssertions, isNull);
    expect(options.loaderExtension, '.dart.js');
    expect(options.compilers, [
      isA<EnabledEntrypointCompiler>()
          .having((e) => e.compiler, 'compiler', WebCompiler.Dart2Js)
          .having((e) => e.compilerArguments, 'compilerArguments', ['-O4'])
          .having((e) => e.extension, 'extension', '.dart2js.js'),
      isA<EnabledEntrypointCompiler>()
          .having((e) => e.compiler, 'compiler', WebCompiler.Dart2Wasm)
          .having((e) => e.compilerArguments, 'compilerArguments', ['-O3'])
          .having((e) => e.extension, 'extension', '.custom_extension.js'),
    ]);
  });
}
