// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import 'body_guard.dart';
import 'body_weaver.dart';
import 'clause_emitter.dart';
import 'clause_reader.dart';
import 'constructor_weaver.dart';
import 'immutability_detector.dart';
import 'invariant_hooks.dart';
import 'mutation_detector.dart';
import 'reserved_name_checker.dart';
import 'source_edits.dart';

/// Visits a compilation unit and records, in [edits], the edits that weave in
/// its contracts.
class ContractCollector extends RecursiveAstVisitor<void> {
  ContractCollector(this.edits)
    : _reader = ClauseReader(edits.source),
      _bodyWeaver = BodyWeaver(edits) {
    _constructorWeaver = ConstructorWeaver(edits, _reader, _bodyWeaver);
  }

  final SourceEdits edits;
  final ClauseReader _reader;
  final BodyWeaver _bodyWeaver;
  late final ConstructorWeaver _constructorWeaver;

  @override
  void visitCompilationUnit(CompilationUnit node) {
    final declaredClasses = {
      for (final declaration in node.declarations.whereType<ClassDeclaration>())
        declaration.namePart.typeName.lexeme,
    };
    if (declaredClasses.intersection(ClauseReader.annotationNames).isNotEmpty) {
      final support = ClauseEmitter.runtimeSupport(
        includeContracts: !declaredClasses.contains('Contracts'),
        includeViolation: !declaredClasses.contains('ContractViolation'),
      );
      if (support.isNotEmpty) {
        edits.insert(edits.source.length, '\n$support');
      }
    }
    super.visitCompilationUnit(node);
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final body = node.body;
    if (body is! BlockClassBody) return;

    final className = node.namePart.typeName.lexeme;
    final isImmutable = ImmutabilityDetector.isImmutable(node);

    final invariants = _reader.invariants(node.metadata);
    final hasInvariant = invariants.isNotEmpty;
    if (hasInvariant) {
      // Inject the `_checkInvariants` extension after the class.
      final extension = ClauseEmitter.invariantExtension(
        className,
        node.namePart.typeParameters,
        invariants,
      );
      edits.insert(node.end, '\n$extension\n');
    }

    for (final member in body.members) {
      if (member is ConstructorDeclaration) {
        _constructorWeaver.weave(
          member,
          className: className,
          classHasInvariant: hasInvariant,
        );
      } else if (member is MethodDeclaration) {
        _weaveMethod(
          member,
          className: className,
          classHasInvariant: hasInvariant,
          classIsImmutable: isImmutable,
        );
      }
    }
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    final contract = _reader.read(node.metadata);
    if (contract.isEmpty) return;
    final returnType = node.returnType?.toSource();
    final isVoid = returnType == 'void';
    ReservedNameChecker.check(
      node.functionExpression.parameters,
      bindsResult: contract.postconditions.isNotEmpty && !isVoid,
      bindsSignal: contract.throwClauses.isNotEmpty,
    );

    _bodyWeaver.weave(
      node.functionExpression.body,
      returnType: returnType,
      isVoid: isVoid,
      preconditions: contract.preconditions,
      postconditions: contract.postconditions,
      guard: BodyGuard.of(throwClauses: contract.throwClauses),
    );
  }

  void _weaveMethod(
    MethodDeclaration node, {
    required String className,
    required bool classHasInvariant,
    required bool classIsImmutable,
  }) {
    if (node.body is EmptyFunctionBody) return;

    final contract = _reader.read(node.metadata);
    final returnType = node.returnType?.toSource();
    final isVoid = node.isSetter || returnType == 'void';
    ReservedNameChecker.check(
      node.parameters,
      bindsResult: contract.postconditions.isNotEmpty && !isVoid,
      bindsSignal: contract.throwClauses.isNotEmpty,
    );
    final methodName = node.name.lexeme;
    final isExcludedFromInvariants =
        node.isGetter ||
        methodName == '==' ||
        methodName == 'hashCode' ||
        methodName == 'toString';
    final isPublicInstance =
        !node.isStatic &&
        !methodName.startsWith('_') &&
        !isExcludedFromInvariants;
    final checkInvariant = classHasInvariant && isPublicInstance;

    if (contract.isEmpty && !checkInvariant) return;

    _bodyWeaver.weave(
      node.body,
      returnType: returnType,
      isVoid: isVoid,
      preconditions: contract.preconditions,
      postconditions: contract.postconditions,
      guard: BodyGuard.of(
        invariant: checkInvariant
            ? InvariantHooks.of(
                className: className,
                mightMutate:
                    !classIsImmutable &&
                    MutationDetector.mightMutateState(node),
              )
            : null,
        throwClauses: contract.throwClauses,
      ),
    );
  }
}
