// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';

import 'body_guard.dart';
import 'reentrancy_guard.dart';
import 'throw_clauses.dart';

/// Generates the code that checks contract clauses.
class ClauseEmitter {
  /// Runtime declarations injected into the library that declares the contract
  /// annotations.
  static String runtimeSupport({
    required bool includeContracts,
    required bool includeViolation,
  }) {
    final buffer = StringBuffer();
    if (includeContracts) {
      buffer.writeln(
        'class Contracts {\n'
        '  static bool checking = false;\n'
        '  static final Expando<int> openScopes = Expando<int>();\n'
        '}\n',
      );
    }
    if (includeViolation) {
      buffer.writeln(
        'class ContractViolation implements Exception {\n'
        '  final String message;\n'
        '  ContractViolation(this.message);\n'
        '  @override\n'
        "  String toString() => 'ContractViolation: \$message';\n"
        '}\n',
      );
    }
    return '$buffer';
  }

  static String preconditions(Iterable<String> clauses) =>
      ReentrancyGuard.wrap(_throwIfFalse('Precondition', clauses));

  static String postconditions(Iterable<String> clauses) =>
      ReentrancyGuard.wrap(_throwIfFalse('Postcondition', clauses));

  /// A `catch` clause that checks [throwClauses] and rethrows.
  ///
  /// [beforeChecks] runs first, whatever the clauses say.
  static String exceptionalPostconditions(
    ThrowClauses throwClauses, {
    String beforeChecks = '',
  }) {
    final checks = ReentrancyGuard.wrap(
      _throwIfFalse('Exceptional postcondition', throwClauses.clauses),
    );
    return 'on ${throwClauses.type} catch (signal) {\n'
        '$beforeChecks'
        '$checks'
        'rethrow;\n'
        '}\n';
  }

  /// Enters an invariant scope on entry to a method, checking the invariant if
  /// no other scope on the object is open.
  static const invariantEntry = 'this._enterInvariantScope();\n';

  /// Enters an invariant scope on entry to a constructor body.
  ///
  /// The object is not finished, so the invariant is not checked; the scope
  /// stops public methods called by the constructor from checking it.
  static const constructorEntry = 'this._enterInvariantScope(check: false);\n';

  /// Leaves the invariant scope opened by [invariantEntry] or
  /// [constructorEntry], checking the invariant if it was the outermost.
  static const invariantExit = 'this._exitInvariantScope();\n';

  /// Opens the region that [guardClose] closes.
  static String guardOpen(BodyGuard guard) {
    if (guard.isEmpty) return '';
    // The exception being unwound is captured so that a violation reported by
    // the invariant check can name the exception it discards.
    final declaration = guard.checksInvariant ? 'Object? \$inFlight;\n' : '';
    return '${declaration}try {\n';
  }

  /// Closes the region that [guardOpen] opens, running the checks of [guard]
  /// however the body exits.
  static String guardClose(BodyGuard guard) {
    if (guard.isEmpty) return '';
    final checksInvariant = guard.checksInvariant;
    final buffer = StringBuffer();
    for (final clauses in guard.throwClauses) {
      buffer.write(
        exceptionalPostconditions(
          clauses,
          beforeChecks: checksInvariant ? '\$inFlight = signal;\n' : '',
        ),
      );
    }
    if (!checksInvariant) return '}\n$buffer';

    buffer.writeln('catch (\$thrown) {');
    buffer.writeln(r'$inFlight = $thrown;');
    buffer.writeln('rethrow;');
    buffer.writeln('} finally {');
    buffer.writeln(r'this._exitInvariantScope(during: $inFlight);');
    buffer.writeln('}');
    return '} $buffer';
  }

  /// The name of the extension that holds the invariant check for [className].
  static String invariantExtensionName(String className) =>
      '_ContractsOn\$$className';

  /// An extension on [className] declaring the invariant check and the scope
  /// tracking that decides when it runs.
  ///
  /// As in Cofoja, the invariant is checked on entry and exit of a call only
  /// if no other call on the same object is in progress: inside a call, the
  /// object may legitimately be between states. Open scopes are counted per
  /// object in `Contracts.openScopes`, shared by all classes, so that a call
  /// from a subclass method to a superclass method counts as nested.
  ///
  /// The members are extension members, not class members, because a class
  /// member would become part of the class interface: a library private member
  /// in the interface makes the class impossible to implement from another
  /// library.
  ///
  /// The check takes the exception it is unwinding from, if any. Throwing a
  /// violation then discards that exception, so the violation names it.
  static String invariantExtension(
    String className,
    TypeParameterList? typeParameters,
    Iterable<String> clauses,
  ) {
    final parameters = typeParameters?.toSource() ?? '';
    final names = typeParameters?.typeParameters
        .map((t) => t.name.lexeme)
        .join(', ');
    final arguments = names == null ? '' : '<$names>';
    final guarded = ReentrancyGuard.wrap(
      _throwIfFalse('Invariant', clauses, during: r'$inFlight'),
    );
    // The entry check runs before the scope opens, so that a violation leaves
    // no scope open. The exit check runs after it closes, for the same reason.
    return 'extension ${invariantExtensionName(className)}$parameters '
        'on $className$arguments {\n'
        'void _enterInvariantScope({bool check = true}) {\n'
        'final open = Contracts.openScopes[this] ?? 0;\n'
        'if (check && open == 0) _checkInvariants();\n'
        'Contracts.openScopes[this] = open + 1;\n'
        '}\n'
        'void _exitInvariantScope({Object? during}) {\n'
        'final open = Contracts.openScopes[this]! - 1;\n'
        'Contracts.openScopes[this] = open == 0 ? null : open;\n'
        'if (open == 0) _checkInvariants(during: during);\n'
        '}\n'
        'void _checkInvariants({Object? during}) {\n'
        r"final inFlight = during == null ? '' "
        r": ', thrown while handling $during';"
        '\n'
        '$guarded'
        '}\n'
        '}\n';
  }

  /// Checks that throw if any of [clauses] is false.
  ///
  /// [during] is appended to the message, for a check that runs while an
  /// exception is unwinding.
  static String _throwIfFalse(
    String kind,
    Iterable<String> clauses, {
    String during = '',
  }) {
    final buffer = StringBuffer();
    for (final clause in clauses) {
      buffer.writeln(
        'if (!($clause)) throw ContractViolation('
        "'$kind failed: ${_escape(clause)}$during');",
      );
    }
    return buffer.toString();
  }

  /// [clause] escaped for embedding in a single quoted Dart string literal.
  ///
  /// Contract clauses are valid Dart expressions, so they can contain
  /// characters that are special inside a string literal. Record field access
  /// such as `result.$1` is the common case.
  static String _escape(String clause) => clause
      .replaceAll(r'\', r'\\')
      .replaceAll("'", r"\'")
      .replaceAll(r'$', r'\$');
}
