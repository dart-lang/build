// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../build_plan/build_paths.dart';
import '../constants.dart';
import 'compile_type.dart';
import 'compiler.dart';

const entrypointDillPath = '$entrypointScriptPath.dill';
const entrypointDillDepfilePath = '$entrypointScriptPath.dill.deps';
const entrypointDillDigestPath = '$entrypointScriptPath.dill.digest';

/// Compiles the build script to kernel.
class KernelCompiler extends BaseCompiler {
  KernelCompiler(BuildPaths buildPaths)
    : super(
        buildPaths: buildPaths,
        relativeOutputPath: entrypointDillPath,
        relativeDepfilePath: entrypointDillDepfilePath,
        relativeDigestPath: entrypointDillDigestPath,
        compileSubcommand: 'kernel',
      );

  @override
  CompileType get compileType => CompileType.jit;

  @override
  String cleanStderr(String stderr) =>
      stderr.replaceAll('Bad state: Generating kernel failed!', '').trim();
}
