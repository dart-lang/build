// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/analyzer.dart';
import 'package:build/build.dart';

import 'dart2js_bootstrap.dart';
import 'dev_compiler_bootstrap.dart';

const ddcBootstrapExtension = '.dart.bootstrap.js';
const jsEntrypointExtension = '.dart.js';
const jsEntrypointSourceMapExtension = '.dart.js.map';

/// Which compiler to use when compiling web entrypoints.
enum WebCompiler {
  Dart2Js,
  DartDevc,
}

/// The top level keys supported for the `options` config for the
/// [WebEntrypointBuilder].
const _supportedOptions = const ['compiler', 'dart2js_args'];

/// A builder which compiles entrypoints for the web.
///
/// Supports `dart2js` and `dartdevc`.
class WebEntrypointBuilder implements Builder {
  final WebCompiler webCompiler;
  final List<String> dart2JsArgs;
  final bool useKernel;

  const WebEntrypointBuilder(this.webCompiler,
      {this.dart2JsArgs: const [], this.useKernel: false});

  factory WebEntrypointBuilder.fromOptions(BuilderOptions options) {
    var unsupportedOptions =
        options.config.keys.where((o) => !_supportedOptions.contains(o));
    if (unsupportedOptions.isNotEmpty) {
      throw new ArgumentError.value(
          unsupportedOptions.join(', '),
          'build_web_compilers|entrypoint',
          'only $_supportedOptions are supported options, but got');
    }
    var compilerOption = options.config['compiler'] as String ?? 'dartdevc';
    WebCompiler compiler;
    switch (compilerOption) {
      case 'dartdevc':
        compiler = WebCompiler.DartDevc;
        break;
      case 'dart2js':
        compiler = WebCompiler.Dart2Js;
        break;
      default:
        throw new ArgumentError.value(compilerOption, 'compiler',
            'Only `dartdevc` and `dart2js` are supported.');
    }

    var dart2JsArgs = options.config['dart2js_args'] ?? <String>[];
    if (dart2JsArgs is! List<String>) {
      throw new ArgumentError.value(dart2JsArgs, 'dart2js_args',
          'Expected a list of strings, but got a ${dart2JsArgs.runtimeType}:');
    }

    return new WebEntrypointBuilder(compiler,
        dart2JsArgs: dart2JsArgs as List<String>);
  }

  @override
  final buildExtensions = const {
    '.dart': const [
      ddcBootstrapExtension,
      jsEntrypointExtension,
      jsEntrypointSourceMapExtension
    ],
  };

  @override
  Future<Null> build(BuildStep buildStep) async {
    var dartEntrypointId = buildStep.inputId;
    var isAppEntrypoint = await _isAppEntryPoint(dartEntrypointId, buildStep);
    if (!isAppEntrypoint) return;
    if (webCompiler == WebCompiler.DartDevc) {
      await bootstrapDdc(buildStep, useKernel: useKernel);
    } else if (webCompiler == WebCompiler.Dart2Js) {
      await bootstrapDart2Js(buildStep, dart2JsArgs);
    }
  }
}

/// Returns whether or not [dartId] is an app entrypoint (basically, whether
/// or not it has a `main` function).
Future<bool> _isAppEntryPoint(AssetId dartId, AssetReader reader) async {
  assert(dartId.extension == '.dart');
  // Skip reporting errors here, dartdevc will report them later with nicer
  // formatting.
  var parsed = parseCompilationUnit(await reader.readAsString(dartId),
      suppressErrors: true);
  // Allow two or fewer arguments so that entrypoints intended for use with
  // [spawnUri] get counted.
  //
  // TODO: This misses the case where a Dart file doesn't contain main(),
  // but has a part that does, or it exports a `main` from another library.
  return parsed.declarations.any((node) {
    return node is FunctionDeclaration &&
        node.name.name == "main" &&
        node.functionExpression.parameters.parameters.length <= 2;
  });
}
