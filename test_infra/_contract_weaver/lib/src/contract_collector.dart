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
          checksInvariant: hasInvariant && !_isDeclaredImmutable(node),
        );
      }
    }
  }

  /// Whether [node] declares that its instances are immutable: it is a
  /// `built_value` class, or it is annotated `@immutable` from `package:meta`.
  ///
  /// An invariant that held on construction of an immutable object still
  /// holds, so methods do not check it.
  ///
  /// TODO(davidmorgan): this trusts intent. Both `built_value` and
  /// `@immutable` guarantee only shallow immutability: a field may have a
  /// mutable type, and in Dart any class can be implemented, so even
  /// `BuiltList` may be mutable underneath. An invariant reading such state
  /// can be broken without being reported. Checking soundly needs resolved,
  /// closed world analysis of the field types the invariant depends on.
  static bool _isDeclaredImmutable(ClassDeclaration node) {
    final isBuiltValue =
        node.implementsClause?.interfaces.any(
          (type) => type.name.lexeme == 'Built',
        ) ??
        false;
    return isBuiltValue ||
        node.metadata.any(
          (annotation) =>
              annotation.arguments == null &&
              (annotation.name.name == 'immutable' ||
                  annotation.name.name.endsWith('.immutable')),
        );
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    final contract = _reader.read(node.metadata);
    if (contract.isEmpty) return;
    final returnType = node.returnType?.toSource();
    final isVoid = _returnsNothing(returnType, node.functionExpression.body);
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

  /// Weaves the contract of [node] into it; if [checksInvariant], public
  /// instance methods also become invariant scopes.
  void _weaveMethod(MethodDeclaration node, {required bool checksInvariant}) {
    final contract = _reader.read(node.metadata);
    if (node.body is EmptyFunctionBody) {
      // An abstract or external method has no body to weave into. Contracts
      // are not inherited by overrides, so silently ignoring them would be
      // worse.
      if (contract.isEmpty) return;
      throw FormatException(
        'Contracts are not supported on methods with no body: '
        '${node.name.lexeme}.',
      );
    }

    final returnType = node.returnType?.toSource();
    final isVoid = node.isSetter || _returnsNothing(returnType, node.body);
    ReservedNameChecker.check(
      node.parameters,
      bindsResult: contract.postconditions.isNotEmpty && !isVoid,
      bindsSignal: contract.throwClauses.isNotEmpty,
    );
    final checkInvariant = checksInvariant && _isInvariantScope(node);
    if (contract.isEmpty && !checkInvariant) return;

    _bodyWeaver.weave(
      node.body,
      returnType: returnType,
      isVoid: isVoid,
      preconditions: contract.preconditions,
      postconditions: contract.postconditions,
      guard: BodyGuard.of(
        checksInvariant: checkInvariant,
        throwClauses: contract.throwClauses,
      ),
    );
  }

  /// Whether a function declared to return [returnType] with [body] returns
  /// no value: it is `void`, or it is `async` and returns `Future<void>`.
  ///
  /// Postconditions of such a function are also checked when it falls off the
  /// end of its body, and do not bind `result`.
  static bool _returnsNothing(String? returnType, FunctionBody body) {
    if (returnType == 'void') return true;
    if (!body.isAsynchronous || body.isGenerator) return false;
    return returnType == 'Future<void>' || returnType == 'FutureOr<void>';
  }

  /// Whether calls to [node] check the invariant of a class that has one.
  ///
  /// Public instance methods and setters do. Getters, `==`, `hashCode` and
  /// `toString` do not, so that invariants can use them.
  static bool _isInvariantScope(MethodDeclaration node) {
    final name = node.name.lexeme;
    if (node.isStatic || name.startsWith('_')) return false;
    if (node.isGetter) return false;
    if (name == '==' || name == 'hashCode' || name == 'toString') return false;
    // An iterator that is abandoned never runs the code that would leave the
    // scope, which would turn the invariant off for the object.
    return !node.body.isGenerator;
  }
}
