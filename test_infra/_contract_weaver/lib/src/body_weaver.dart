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

    if (body is ExpressionFunctionBody) {
      final exprSource = edits.textAt(
        body.expression.offset,
        body.expression.end,
      );

      final buffer = StringBuffer('{\n');
      if (guard.invariant != null) {
        buffer.write(ClauseEmitter.invariantCheck);
      }
      if (preconditions.isNotEmpty) {
        buffer.write(ClauseEmitter.preconditions(preconditions));
      }
      buffer.write(ClauseEmitter.guardOpen(guard));

      if (postconditions.isNotEmpty) {
        if (isVoid) {
          buffer.writeln('$exprSource;');
          buffer.write(ClauseEmitter.postconditions(postconditions));
        } else {
          buffer.writeln(
            exitRewriter.returnValue(
              exprSource,
              ClauseEmitter.postconditions(postconditions),
            ),
          );
        }
      } else if (isVoid) {
        buffer.writeln('$exprSource;');
      } else {
        buffer.writeln('return $exprSource;');
      }

      buffer.write(ClauseEmitter.guardClose(guard));
      buffer.write('}');

      final startOffset = body.functionDefinition.offset;
      edits.replace(startOffset, body.end - startOffset, buffer.toString());
    } else if (body is BlockFunctionBody) {
      final entryBuffer = StringBuffer();
      if (guard.invariant != null) {
        entryBuffer.write(ClauseEmitter.invariantCheck);
      }
      if (preconditions.isNotEmpty) {
        entryBuffer.write(ClauseEmitter.preconditions(preconditions));
      }
      entryBuffer.write(ClauseEmitter.guardOpen(guard));

      if (entryBuffer.isNotEmpty) {
        edits.insert(body.block.leftBracket.end, '\n$entryBuffer\n');
      }

      if (postconditions.isNotEmpty) {
        weaveReturns(body.block, postconditions, exitRewriter);
      }

      final closingBuffer = StringBuffer('\n');
      final lastStatement = body.block.statements.isNotEmpty
          ? body.block.statements.last
          : null;
      if (isVoid && lastStatement is! ReturnStatement) {
        if (postconditions.isNotEmpty) {
          closingBuffer.write(ClauseEmitter.postconditions(postconditions));
        }
      }
      closingBuffer.write(ClauseEmitter.guardClose(guard));
      if (closingBuffer.length > 1) {
        edits.insert(body.block.rightBracket.offset, closingBuffer.toString());
      }
    }
  }

  /// Rewrites each `return` in [block] to check [postconditions] first.
  void weaveReturns(
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
