// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';

import 'body_weaver.dart';
import 'clause_emitter.dart';
import 'clause_reader.dart';
import 'exit_rewriter.dart';
import 'member_contract.dart';
import 'reserved_name_checker.dart';
import 'return_statement_collector.dart';
import 'source_edits.dart';

/// Weaves checks into constructors.
///
/// Constructors have their own entry and exit assembly, which differs from that
/// of methods: generative constructors return nothing, and have no place for a
/// catch clause around their initializers.
class ConstructorWeaver {
  ConstructorWeaver(this.edits, this.reader, this.bodyWeaver);

  final SourceEdits edits;
  final ClauseReader reader;
  final BodyWeaver bodyWeaver;

  /// Weaves the contract of [node], a constructor of [className], into it.
  ///
  /// If [classHasInvariant], generative constructors also check the invariant
  /// on exit. Constructors that cannot be woven are skipped without reading
  /// their annotations.
  void weave(
    ConstructorDeclaration node, {
    required String className,
    required bool classHasInvariant,
  }) {
    if (node.redirectedConstructor != null) return;
    if (node.constKeyword != null) return;

    // There is no place to put a catch clause. Silently ignoring the
    // annotation would be worse.
    if (reader.throwClauses(node.metadata).isNotEmpty) {
      throw const FormatException(
        '@ThrowEnsures is not supported on constructors.',
      );
    }

    if (node.factoryKeyword != null) {
      _weaveFactory(
        node,
        className: className,
        contract: reader.read(node.metadata),
      );
      return;
    }

    if (node.initializers.any((i) => i is RedirectingConstructorInvocation)) {
      return;
    }
    _weaveGenerative(
      node,
      classHasInvariant: classHasInvariant,
      contract: reader.read(node.metadata),
    );
  }

  void _weaveFactory(
    ConstructorDeclaration node, {
    required String className,
    required MemberContract contract,
  }) {
    final preconditions = contract.preconditions;
    final postconditions = contract.postconditions;
    if (preconditions.isEmpty && postconditions.isEmpty) return;
    ReservedNameChecker.check(
      node.parameters,
      bindsResult: postconditions.isNotEmpty,
      bindsSignal: false,
    );

    final body = node.body;
    final exitRewriter = ExitRewriter(returnType: className, isAsync: false);
    if (body is ExpressionFunctionBody) {
      final exprSource = edits.textAt(
        body.expression.offset,
        body.expression.end,
      );
      final buffer = StringBuffer('{\n');
      if (preconditions.isNotEmpty) {
        buffer.write(ClauseEmitter.preconditions(preconditions));
      }

      if (postconditions.isNotEmpty) {
        buffer.writeln(
          exitRewriter.returnValue(
            exprSource,
            ClauseEmitter.postconditions(postconditions),
          ),
        );
      } else {
        buffer.writeln('return $exprSource;');
      }
      buffer.write('}');

      final startOffset = body.functionDefinition.offset;
      edits.replace(startOffset, body.end - startOffset, buffer.toString());
    } else if (body is BlockFunctionBody) {
      if (preconditions.isNotEmpty) {
        edits.insert(
          body.block.leftBracket.end,
          '\n${ClauseEmitter.preconditions(preconditions)}\n',
        );
      }
      if (postconditions.isNotEmpty) {
        bodyWeaver.weaveReturns(body.block, postconditions, exitRewriter);
      }
    }
  }

  void _weaveGenerative(
    ConstructorDeclaration node, {
    required bool classHasInvariant,
    required MemberContract contract,
  }) {
    final preconditions = contract.preconditions;
    final postconditions = contract.postconditions;
    final hasPre = preconditions.isNotEmpty;
    final hasPost = postconditions.isNotEmpty;
    if (!hasPre && !hasPost && !classHasInvariant) return;
    ReservedNameChecker.check(
      node.parameters,
      bindsResult: false,
      bindsSignal: false,
    );

    /// The checks that run on exit.
    String exitChecks() {
      final buffer = StringBuffer();
      if (classHasInvariant) buffer.writeln('this._checkInvariants();');
      if (hasPost) buffer.write(ClauseEmitter.postconditions(postconditions));
      return '$buffer';
    }

    final body = node.body;
    if (body is EmptyFunctionBody) {
      final buffer = StringBuffer('{\n');
      if (hasPre) buffer.write(ClauseEmitter.preconditions(preconditions));
      buffer
        ..write(exitChecks())
        ..write('}');
      edits.replace(
        body.semicolon.offset,
        body.semicolon.length,
        buffer.toString(),
      );
    } else if (body is BlockFunctionBody) {
      if (hasPre) {
        edits.insert(
          body.block.leftBracket.end,
          '\n${ClauseEmitter.preconditions(preconditions)}\n',
        );
      }
      if (classHasInvariant || hasPost) {
        for (final ret in ReturnStatementCollector.collect(body.block)) {
          edits.replace(ret.offset, ret.length, '{\n${exitChecks()}return;\n}');
        }

        final lastStatement = body.block.statements.isNotEmpty
            ? body.block.statements.last
            : null;
        if (lastStatement is! ReturnStatement) {
          edits.insert(body.block.rightBracket.offset, '\n${exitChecks()}');
        }
      }
    }
  }
}
