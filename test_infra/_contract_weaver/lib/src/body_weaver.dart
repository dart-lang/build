// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';

import 'body_guard.dart';
import 'clause_emitter.dart';
import 'exit_rewriter.dart';
import 'return_statement_collector.dart';
import 'source_edits.dart';

/// Weaves checks into the body of a function or method.
class BodyWeaver {
  BodyWeaver(this.edits);

  final SourceEdits edits;

  /// Weaves [preconditions], [postconditions] and [guard] into [body].
  void weave(
    FunctionBody body, {
    required String? returnType,
    required bool isVoid,
    required Iterable<String> preconditions,
    required Iterable<String> postconditions,
    required BodyGuard guard,
  }) {
    final exitRewriter = ExitRewriter(
      returnType: returnType,
      isAsync: body.isAsynchronous,
    );
    final entry = _entry(preconditions, guard);
    if (body is ExpressionFunctionBody) {
      _weaveExpressionBody(
        body,
        entry: entry,
        result: _expressionResult(
          edits.textAt(body.expression.offset, body.expression.end),
          isVoid: isVoid,
          isAsync: body.isAsynchronous,
          postconditions: postconditions,
          exitRewriter: exitRewriter,
        ),
        guard: guard,
      );
    } else if (body is BlockFunctionBody) {
      _weaveBlockBody(
        body,
        entry: entry,
        isVoid: isVoid,
        postconditions: postconditions,
        exitRewriter: exitRewriter,
        guard: guard,
      );
    } else {
      throw const FormatException(
        'Cannot weave contracts into a function with no body, such as an '
        'external one.',
      );
    }
  }

  /// The code that runs before the original body.
  ///
  /// Nothing may throw between entering the invariant scope and opening the
  /// guard that leaves it, so preconditions come first.
  String _entry(Iterable<String> preconditions, BodyGuard guard) {
    final buffer = StringBuffer();
    if (preconditions.isNotEmpty) {
      buffer.write(ClauseEmitter.preconditions(preconditions));
    }
    if (guard.checksInvariant) {
      buffer.write(ClauseEmitter.invariantEntry);
    }
    buffer.write(ClauseEmitter.guardOpen(guard));
    return buffer.toString();
  }

  /// The statements that evaluate [exprSource], check [postconditions] and
  /// return the result.
  String _expressionResult(
    String exprSource, {
    required bool isVoid,
    required bool isAsync,
    required Iterable<String> postconditions,
    required ExitRewriter exitRewriter,
  }) {
    final checks = postconditions.isEmpty
        ? ''
        : ClauseEmitter.postconditions(postconditions);
    // In an `async` function, `=> e` waits for `e` if it is a future, so the
    // checks must wait too.
    if (isVoid) return '${isAsync ? 'await ' : ''}$exprSource;\n$checks';
    if (postconditions.isEmpty) return 'return $exprSource;\n';
    return '${exitRewriter.returnValue(exprSource, checks)}\n';
  }

  /// Replaces `=> expr` with a block that runs [entry], then [result].
  void _weaveExpressionBody(
    ExpressionFunctionBody body, {
    required String entry,
    required String result,
    required BodyGuard guard,
  }) {
    final startOffset = body.functionDefinition.offset;
    edits.replace(
      startOffset,
      body.end - startOffset,
      '{\n$entry$result${ClauseEmitter.guardClose(guard)}}',
    );
  }

  /// Inserts [entry] at the start of the block, checks [postconditions] at
  /// each exit, and closes [guard] at the end.
  void _weaveBlockBody(
    BlockFunctionBody body, {
    required String entry,
    required bool isVoid,
    required Iterable<String> postconditions,
    required ExitRewriter exitRewriter,
    required BodyGuard guard,
  }) {
    final block = body.block;
    if (entry.isNotEmpty) {
      edits.insert(block.leftBracket.end, '\n$entry\n');
    }

    if (postconditions.isNotEmpty) {
      _weaveReturns(block, postconditions, exitRewriter);
    }

    final closing = StringBuffer();
    final fallsOffEnd =
        block.statements.isEmpty || block.statements.last is! ReturnStatement;
    if (isVoid && fallsOffEnd && postconditions.isNotEmpty) {
      closing.write(ClauseEmitter.postconditions(postconditions));
    }
    closing.write(ClauseEmitter.guardClose(guard));
    if (closing.isNotEmpty) {
      edits.insert(block.rightBracket.offset, '\n$closing');
    }
  }

  /// Rewrites each `return` in [block] to check [postconditions] first.
  void _weaveReturns(
    Block block,
    Iterable<String> postconditions,
    ExitRewriter exitRewriter,
  ) {
    for (final statement in ReturnStatementCollector.collect(block)) {
      final expr = statement.expression;
      if (expr != null) {
        final exprSource = edits.textAt(expr.offset, expr.end);
        edits.replace(
          statement.offset,
          statement.length,
          exitRewriter.returnValue(
            exprSource,
            ClauseEmitter.postconditions(postconditions),
          ),
        );
      } else {
        final buffer = StringBuffer('{\n')
          ..write(ClauseEmitter.postconditions(postconditions))
          ..writeln('return;')
          ..write('}');
        edits.replace(statement.offset, statement.length, buffer.toString());
      }
    }
  }
}
