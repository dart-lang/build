// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

/// Counts contract annotations, so that a run can report how many clauses it
/// wove and a misspelled annotation shows as a count lower than expected.
class ClauseCounter extends RecursiveAstVisitor<void> {
  ClauseCounter._();

  /// The annotation names counted, in the order they are reported.
  static const names = ['Requires', 'Ensures', 'ThrowEnsures', 'Invariant'];

  final Map<String, int> _counts = {for (final name in names) name: 0};

  /// The number of annotations in [source] with each of [names].
  static Map<String, int> count(String source) {
    final counter = ClauseCounter._();
    parseString(content: source).unit.accept(counter);
    return counter._counts;
  }

  @override
  void visitAnnotation(Annotation node) {
    final name = node.name.name;
    final count = _counts[name];
    if (count != null) _counts[name] = count + 1;
    super.visitAnnotation(node);
  }
}
