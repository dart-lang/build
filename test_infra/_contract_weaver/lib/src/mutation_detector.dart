// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

/// Guesses, without resolution, whether code might change the object it runs
/// on.
///
/// A guess of "no" lets the invariant check keep its memoized result, so it
/// must err towards "yes".
class MutationDetector extends RecursiveAstVisitor<void> {
  bool mightMutate = false;

  static const _mutatingPrefixes = [
    'add',
    'remove',
    'clear',
    'put',
    'update',
    'replace',
    'set',
    'insert',
    'fill',
    'sort',
    'shuffle',
    'mark',
    'copy',
    'record',
    'reset',
    'write',
    'delete',
    'evict',
    'invalidate',
    'register',
    'unregister',
    'modify',
    'mutate',
  ];

  /// Whether [method] might change the object it runs on.
  ///
  /// Setters always might. Otherwise the body is scanned for assignments,
  /// increments and calls to methods with mutating names.
  static bool mightMutateState(MethodDeclaration method) {
    if (method.isSetter) return true;
    final detector = MutationDetector();
    method.body.accept(detector);
    return detector.mightMutate;
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    mightMutate = true;
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    if (node.operator.lexeme == '++' || node.operator.lexeme == '--') {
      mightMutate = true;
    }
    super.visitPostfixExpression(node);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    if (node.operator.lexeme == '++' || node.operator.lexeme == '--') {
      mightMutate = true;
    }
    super.visitPrefixExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final name = node.methodName.name;
    for (final prefix in _mutatingPrefixes) {
      if (name.startsWith(prefix)) {
        mightMutate = true;
        break;
      }
    }
    super.visitMethodInvocation(node);
  }
}
