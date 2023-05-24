// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:build/build.dart';
import 'package:build_modules/build_modules.dart';

import 'common.dart';
import 'dart2js_bootstrap.dart';
import 'dev_compiler_bootstrap.dart';

const ddcBootstrapExtension = '.dart.bootstrap.js';
const jsEntrypointExtension = '.dart.js';
const jsEntrypointSourceMapExtension = '.dart.js.map';
const jsEntrypointArchiveExtension = '.dart.js.tar.gz';
const digestsEntrypointExtension = '.digests';
const mergedMetadataExtension = '.dart.ddc_merged_metadata';

/// Which compiler to use when compiling web entrypoints.
enum WebCompiler {
  // ignore: constant_identifier_names
  Dart2Js,
  // ignore: constant_identifier_names
  DartDevc,
}

/// The top level keys supported for the `options` config for the
/// [WebEntrypointBuilder].
const _supportedOptions = [
  _compilerOption,
  _dart2jsArgsOption,
  _nativeNullAssertionsOption,
];

const _compilerOption = 'compiler';
const _dart2jsArgsOption = 'dart2js_args';
const _nativeNullAssertionsOption = 'native_null_assertions';

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

  /// Whether or not to enable runtime non-null assertions for values returned
  /// from browser apis.
  ///
  /// If `null` then no flag will be provided to the compiler, and the default
  /// will be used.
  final bool? nativeNullAssertions;

  const WebEntrypointBuilder(
    this.webCompiler, {
    this.dart2JsArgs = const [],
    required this.nativeNullAssertions,
  });

  factory WebEntrypointBuilder.fromOptions(BuilderOptions options) {
    validateOptions(
        options.config, _supportedOptions, 'build_web_compilers:entrypoint',
        deprecatedOptions: _deprecatedOptions);
    var compilerOption =
        options.config[_compilerOption] as String? ?? 'dartdevc';
    WebCompiler compiler;
    switch (compilerOption) {
      case 'dartdevc':
        compiler = WebCompiler.DartDevc;
        break;
      case 'dart2js':
        compiler = WebCompiler.Dart2Js;
        break;
      default:
        throw ArgumentError.value(compilerOption, _compilerOption,
            'Only `dartdevc` and `dart2js` are supported.');
    }

    if (options.config[_dart2jsArgsOption] is! List) {
      var message = options.config[_dart2jsArgsOption] is String
          ? 'There may have been a failure decoding as JSON, expected a list'
          : 'Expected a list';
      throw ArgumentError.value(
          options.config[_dart2jsArgsOption], _dart2jsArgsOption, message);
    }
    var dart2JsArgs = (options.config[_dart2jsArgsOption] as List?)
            ?.map((arg) => '$arg')
            .toList() ??
        const <String>[];

    return WebEntrypointBuilder(compiler,
        dart2JsArgs: dart2JsArgs,
        nativeNullAssertions:
            options.config[_nativeNullAssertionsOption] as bool?);
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
        break;
      case WebCompiler.Dart2Js:
        await bootstrapDart2Js(buildStep, dart2JsArgs,
            nativeNullAssertions: nativeNullAssertions);
        break;
    }
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
