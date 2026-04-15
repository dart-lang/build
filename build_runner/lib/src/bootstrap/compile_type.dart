// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../build_plan/build_paths.dart';
import 'aot_compiler.dart';
import 'compiler.dart';
import 'kernel_compiler.dart';

enum CompileType {
  jit,
  aot;

  Compiler createCompiler(BuildPaths buildPaths) {
    switch (this) {
      case CompileType.aot:
        return AotCompiler(buildPaths);
      case CompileType.jit:
        return KernelCompiler(buildPaths);
    }
  }

  String get displayName => this == CompileType.aot ? 'aot' : 'jit';
}

enum CompileStrategy {
  forceJit,

  forceAot,

  /// Try AOT compilation, fall back to JIT if it fails.
  tryAot,

  alwaysJit;

  CompileType get initialCompileType {
    switch (this) {
      case CompileStrategy.forceAot:
      case CompileStrategy.tryAot:
        return CompileType.aot;
      case CompileStrategy.forceJit:
      case CompileStrategy.alwaysJit:
        return CompileType.jit;
    }
  }
}
