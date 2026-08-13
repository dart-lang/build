// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../build_plan/build_paths.dart';
import '../constants.dart';
import 'compile_type.dart';
import 'compiler.dart';

const entrypointAotPath = '$entrypointScriptPath.aot';
const entrypointAotDepfilePath = '$entrypointScriptPath.aot.deps';
const entrypointAotDigestPath = '$entrypointScriptPath.aot.digest';

/// Compiles the build script to an AOT snapshot.
class AotCompiler extends BaseCompiler {
  AotCompiler(BuildPaths buildPaths)
    : super(
        buildPaths: buildPaths,
        relativeOutputPath: entrypointAotPath,
        relativeDepfilePath: entrypointAotDepfilePath,
        relativeDigestPath: entrypointAotDigestPath,
        compileSubcommand: 'aot-snapshot',
      );

  @override
  CompileType get compileType => CompileType.aot;

  @override
  String cleanStderr(String stderr) => stderr
      .replaceAll('Error: AOT compilation failed', '')
      .replaceAll('Bad state: Generating AOT snapshot failed!', '')
      .trim();
}
