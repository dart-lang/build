// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import 'clause_reader.dart';

/// Rejects contracts on local functions, which the weaver does not weave.
class LocalFunctionChecker extends RecursiveAstVisitor<void> {
  LocalFunctionChecker._(this._reader);

  final ClauseReader _reader;

  /// Throws if any local function in [unit] has a contract.
  static void check(CompilationUnit unit, ClauseReader reader) {
    unit.accept(LocalFunctionChecker._(reader));
  }

  @override
  void visitFunctionDeclarationStatement(FunctionDeclarationStatement node) {
    final declaration = node.functionDeclaration;
    if (!_reader.read(declaration.metadata).isEmpty) {
      throw FormatException(
        'Contracts are not supported on local functions: '
        '${declaration.name.lexeme}.',
      );
    }
    super.visitFunctionDeclarationStatement(node);
  }
}
