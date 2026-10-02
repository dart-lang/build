// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';

/// Rejects parameters that collide with names the weaver binds for clauses.
class ReservedNameChecker {
  /// Throws if [parameters] declares `result` and [bindsResult], or declares
  /// `signal` and [bindsSignal].
  static void check(
    FormalParameterList? parameters, {
    required bool bindsResult,
    required bool bindsSignal,
  }) {
    if (parameters == null) return;
    for (final parameter in parameters.parameters) {
      final name = parameter.name?.lexeme;
      if (bindsResult && name == 'result') {
        throw const FormatException(
          '@Ensures cannot be used on a function with a parameter named '
          '"result".',
        );
      }
      if (bindsSignal && name == 'signal') {
        throw const FormatException(
          '@ThrowEnsures cannot be used on a function with a parameter named '
          '"signal".',
        );
      }
    }
  }
}
