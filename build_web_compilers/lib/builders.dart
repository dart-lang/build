// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:build_web_compilers/build_web_compilers.dart';

Builder moduleBuilder(_) => const ModuleBuilder();
Builder unlinkedSummaryBuilder(_) => const UnlinkedSummaryBuilder();
Builder linkedSummaryBuilder(_) => const LinkedSummaryBuilder();
Builder devCompilerBuilder(_) => const DevCompilerBuilder();
Builder webEntrypointBuilder(BuilderOptions options) {
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

  return new WebEntrypointBuilder(compiler);
}
