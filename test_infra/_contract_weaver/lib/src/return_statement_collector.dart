// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

/// Collects the `return` statements of one body.
///
/// Returns inside nested functions and closures belong to those, so they are
/// not collected.
class ReturnStatementCollector extends RecursiveAstVisitor<void> {
  final List<ReturnStatement> returns = [];

  /// The `return` statements in [node], outside nested functions.
  static List<ReturnStatement> collect(AstNode node) {
    final collector = ReturnStatementCollector();
    node.accept(collector);
    return collector.returns;
  }

  @override
  void visitReturnStatement(ReturnStatement node) {
    returns.add(node);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    // Stop traversal at nested function expressions and closures.
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    // Stop traversal at nested local function declarations.
  }
}
