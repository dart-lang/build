// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'depfile.dart';

/// Compiles the build script.
abstract class Compiler {
  /// Checks freshness of the build script compile output.
  ///
  /// Set [digestsAreFresh] if digests were very recently updated. Then, they
  /// will be re-used from disk if possible instead of recomputed.
  FreshnessResult checkFreshness({required bool digestsAreFresh});

  /// Checks whether [path] in a dependency of the build script compile.
  ///
  /// Call [checkFreshness] first to load the depfile.
  bool isDependency(String path);

  /// Compiles the entrypoint script.
  Future<CompileResult> compile({Iterable<String>? experiments});
}

class CompileResult {
  final String? messages;

  CompileResult({required this.messages});

  bool get succeeded => messages == null;

  @override
  String toString() =>
      'CompileResult(succeeded: $succeeded, messages: $messages)';
}
