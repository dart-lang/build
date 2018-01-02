// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/analyzer.dart';
import 'package:build/build.dart';

import 'dev_compiler_bootstrap.dart';

const ddcBootstrapExtension = '.dart.bootstrap.js';
const jsEntrypointExtension = '.dart.js';
const jsEntrypointSourceMapExtension = '.dart.js.map';

class WebEntrypointBuilder implements Builder {
  const WebEntrypointBuilder();

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
    await bootstrapDdc(buildStep);
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
