// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';

import 'body_guard.dart';
import 'body_weaver.dart';
import 'clause_emitter.dart';
import 'clause_reader.dart';
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

  /// A factory body is woven like a method body that returns [className], with
  /// no invariant scope and no catch clause.
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
    bodyWeaver.weave(
      node.body,
      returnType: className,
      isVoid: false,
      preconditions: preconditions,
      postconditions: postconditions,
      guard: BodyGuard.of(),
    );
  }

  void _weaveGenerative(
    ConstructorDeclaration node, {
    required bool classHasInvariant,
    required MemberContract contract,
  }) {
    final preconditions = contract.preconditions;
    final postconditions = contract.postconditions;
    if (preconditions.isEmpty && postconditions.isEmpty && !classHasInvariant) {
      return;
    }
    ReservedNameChecker.check(
      node.parameters,
      bindsResult: false,
      bindsSignal: false,
    );

    // Preconditions come before the scope opens, so that a failing one leaves
    // no scope open. An exception from the body itself does leave it open, but
    // then the object is never returned.
    final entry = StringBuffer();
    if (preconditions.isNotEmpty) {
      entry.write(ClauseEmitter.preconditions(preconditions));
    }
    if (classHasInvariant) entry.write(ClauseEmitter.constructorEntry);

    // As for methods, postconditions run while the scope is still open.
    final exit = StringBuffer();
    if (postconditions.isNotEmpty) {
      exit.write(ClauseEmitter.postconditions(postconditions));
    }
    if (classHasInvariant) exit.write(ClauseEmitter.invariantExit);

    final body = node.body;
    if (body is EmptyFunctionBody) {
      edits.replace(
        body.semicolon.offset,
        body.semicolon.length,
        '{\n$entry$exit}',
      );
    } else if (body is BlockFunctionBody) {
      _weaveGenerativeBlock(body.block, entry: '$entry', exit: '$exit');
    }
  }

  /// Inserts [entry] at the start of [block] and [exit] before each way out.
  void _weaveGenerativeBlock(
    Block block, {
    required String entry,
    required String exit,
  }) {
    if (entry.isNotEmpty) {
      edits.insert(block.leftBracket.end, '\n$entry\n');
    }
    if (exit.isEmpty) return;
    for (final ret in ReturnStatementCollector.collect(block)) {
      edits.replace(ret.offset, ret.length, '{\n${exit}return;\n}');
    }
    final fallsOffEnd =
        block.statements.isEmpty || block.statements.last is! ReturnStatement;
    if (fallsOffEnd) {
      edits.insert(block.rightBracket.offset, '\n$exit');
    }
  }
}
