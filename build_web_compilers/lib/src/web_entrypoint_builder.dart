// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:build/build.dart';
import 'package:build_modules/build_modules.dart';
import 'package:path/path.dart' as p;

import 'common.dart';
import 'dart2js_bootstrap.dart';
import 'dart2wasm_bootstrap.dart';
import 'dev_compiler_bootstrap.dart';

const ddcBootstrapExtension = '.dart.bootstrap.js';
const jsEntrypointExtension = '.dart.js';
const wasmExtension = '.wasm';
const moduleJsExtension = '.mjs';
const jsEntrypointSourceMapExtension = '.dart.js.map';
const jsEntrypointArchiveExtension = '.dart.js.tar.gz';
const digestsEntrypointExtension = '.digests';
const mergedMetadataExtension = '.dart.ddc_merged_metadata';

/// Which compiler to use when compiling web entrypoints.
enum WebCompiler {
  // ignore: constant_identifier_names
  Dart2Js('dart2js'),
  // ignore: constant_identifier_names
  DartDevc('dartdevc'),
  // ignore: constant_identifier_names
  Dart2Wasm('dart2wasm'),
  // ignore: constant_identifier_names
  Dart2JsAndDart2Wasm('both');

  /// The name of this compiler used when identifying it in builder options.
  final String optionName;

  const WebCompiler(this.optionName);

  static WebCompiler fromOptionName(String name) {
    for (final compiler in values) {
      if (compiler.optionName == name) {
        return compiler;
      }
    }

    final supported = values.map((e) => '`${e.optionName}`').join(', ');

    throw ArgumentError.value(
      name,
      _compilerOption,
      'Unknown web compiler, supported are: $supported.',
    );
  }
}

/// The top level keys supported for the `options` config for the
/// [WebEntrypointBuilder].
const _supportedOptions = [
  _compilerOption,
  _dart2jsArgsOption,
  _nativeNullAssertionsOption,
  _dart2wasmArgsOption,
  _entrypointTemplateOption,
];

const _compilerOption = 'compiler';
const _dart2jsArgsOption = 'dart2js_args';
const _dart2wasmArgsOption = 'dart2wasm_args';
const _nativeNullAssertionsOption = 'native_null_assertions';
const _entrypointTemplateOption = 'entrypoint_template';

/// The deprecated keys for the `options` config for the [WebEntrypointBuilder].
const _deprecatedOptions = [
  'enable_sync_async',
  'ignore_cast_failures',
];

/// A builder which compiles entrypoints for the web.
///
/// Supports `dart2js` and `dartdevc`.
class WebEntrypointBuilder implements Builder {
  final WebCompiler webCompiler;
  final List<String> dart2JsArgs;
  final List<String> dart2WasmArgs;

  /// Whether or not to enable runtime non-null assertions for values returned
  /// from browser apis.
  ///
  /// If `null` then no flag will be provided to the compiler, and the default
  /// will be used.
  final bool? nativeNullAssertions;

  /// The template to use for the entrypoint script when compiling with both
  /// dart2wasm and dart2js.
  ///
  /// When no template is given, we default to the `loader.min.js` file in this
  /// package. In the template, `{{ basename }}` is replaced with the basename
  /// of the Dart entrypoint.
  final String? entrypointTemplate;

  const WebEntrypointBuilder(
    this.webCompiler, {
    this.dart2JsArgs = const [],
    this.dart2WasmArgs = const [],
    required this.nativeNullAssertions,
    this.entrypointTemplate,
  });

  factory WebEntrypointBuilder.fromOptions(BuilderOptions options) {
    validateOptions(
        options.config, _supportedOptions, 'build_web_compilers:entrypoint',
        deprecatedOptions: _deprecatedOptions);
    var compilerOption =
        options.config[_compilerOption] as String? ?? 'dartdevc';
    var compiler = WebCompiler.fromOptionName(compilerOption);

    return WebEntrypointBuilder(
      compiler,
      dart2JsArgs: _parseCompilerOptions(options, _dart2jsArgsOption),
      dart2WasmArgs: _parseCompilerOptions(options, _dart2wasmArgsOption),
      nativeNullAssertions:
          options.config[_nativeNullAssertionsOption] as bool?,
      entrypointTemplate: options.config[_entrypointTemplateOption] as String?,
    );
  }

  @override
  final buildExtensions = const {
    '.dart': [
      ddcBootstrapExtension,
      jsEntrypointExtension,
      jsEntrypointSourceMapExtension,
      jsEntrypointArchiveExtension,
      digestsEntrypointExtension,
      mergedMetadataExtension,
      wasmExtension,
      moduleJsExtension,
    ],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    var dartEntrypointId = buildStep.inputId;
    var isAppEntrypoint = await _isAppEntryPoint(dartEntrypointId, buildStep);
    if (!isAppEntrypoint) return;
    switch (webCompiler) {
      case WebCompiler.DartDevc:
        try {
          await bootstrapDdc(buildStep,
              nativeNullAssertions: nativeNullAssertions,
              requiredAssets: _ddcSdkResources);
        } on MissingModulesException catch (e) {
          log.severe('$e');
        }
      case WebCompiler.Dart2Js:
        await bootstrapDart2Js(buildStep, dart2JsArgs,
            nativeNullAssertions: nativeNullAssertions);
      case WebCompiler.Dart2Wasm:
        await bootstrapDart2Wasm(buildStep, dart2WasmArgs, true);
      case WebCompiler.Dart2JsAndDart2Wasm:
        await Future.wait(
          [
            bootstrapDart2Js(
              buildStep,
              dart2JsArgs,
              nativeNullAssertions: nativeNullAssertions,
              generateEntrypoint: false,
            ),
            bootstrapDart2Wasm(buildStep, dart2WasmArgs, false),
          ],
        );
        final basename = p.url.basenameWithoutExtension(buildStep.inputId.path);

        final entrypointTemplate = this.entrypointTemplate ??
            await buildStep.readAsString(
                AssetId('build_web_compilers', 'lib/src/loader.min.js'));
        final entrypoint =
            entrypointTemplate.replaceAll(r'{{basename}}', basename);
        await buildStep.writeAsString(
          buildStep.inputId.changeExtension(jsEntrypointExtension),
          entrypoint,
        );
    }
  }

  static List<String> _parseCompilerOptions(
      BuilderOptions options, String key) {
    return switch (options.config[key]) {
      null => const [],
      List list => list.map((arg) => '$arg').toList(),
      String other => throw ArgumentError.value(
          other,
          key,
          'There may have been a failure decoding as JSON, expected a list.',
        ),
      var other => throw ArgumentError.value(other, key, 'Expected a list'),
    };
  }
}

/// Returns whether or not [dartId] is an app entrypoint (basically, whether
/// or not it has a `main` function).
Future<bool> _isAppEntryPoint(AssetId dartId, AssetReader reader) async {
  assert(dartId.extension == '.dart');
  // Skip reporting errors here, dartdevc will report them later with nicer
  // formatting.
  var parsed = parseString(
          content: await reader.readAsString(dartId), throwIfDiagnostics: false)
      .unit;
  // Allow two or fewer arguments so that entrypoints intended for use with
  // [spawnUri] get counted.
  //
  // TODO: This misses the case where a Dart file doesn't contain main(),
  // but has a part that does, or it exports a `main` from another library.
  return parsed.declarations.any((node) {
    return node is FunctionDeclaration &&
        node.name.lexeme == 'main' &&
        node.functionExpression.parameters != null &&
        node.functionExpression.parameters!.parameters.length <= 2;
  });
}

/// Files copied from the SDK that are required at runtime to run a DDC
/// application.
final _ddcSdkResources = [
  AssetId('build_web_compilers', 'lib/src/dev_compiler/dart_sdk.js'),
  AssetId('build_web_compilers', 'lib/src/dev_compiler/require.js')
];
