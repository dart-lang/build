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

  /// The invariant check that runs on entry to a method.
  static const invariantCheck = 'this._checkInvariants();\n';

  /// Opens the region that [guardClose] closes.
  static String guardOpen(BodyGuard guard) {
    if (guard.isEmpty) return '';
    // The exception being unwound is captured so that a violation reported by
    // the invariant check can name the exception it discards.
    final declaration = guard.invariant == null ? '' : 'Object? \$inFlight;\n';
    return '${declaration}try {\n';
  }

  /// Closes the region that [guardOpen] opens, running the checks of [guard]
  /// however the body exits.
  static String guardClose(BodyGuard guard) {
    if (guard.isEmpty) return '';
    final invariant = guard.invariant;
    final buffer = StringBuffer();
    for (final clauses in guard.throwClauses) {
      buffer.write(
        exceptionalPostconditions(
          clauses,
          beforeChecks: invariant == null ? '' : '\$inFlight = signal;\n',
        ),
      );
    }
    if (invariant == null) return '}\n$buffer';

    buffer.writeln('catch (\$thrown) {');
    buffer.writeln(r'$inFlight = $thrown;');
    buffer.writeln('rethrow;');
    buffer.writeln('} finally {');
    if (invariant.mightMutate) {
      buffer.writeln(
        '${invariantExtensionName(invariant.className)}'
        '._invariantVerified[this] = false;',
      );
    }
    buffer.writeln(r'this._checkInvariants(during: $inFlight);');
    buffer.writeln('}');
    return '} $buffer';
  }

  /// The name of the extension that holds the invariant check for [className].
  static String invariantExtensionName(String className) =>
      '_ContractsOn\$$className';

  /// An extension on [className] declaring `_checkInvariants`.
  ///
  /// The check is an extension member, not a class member, because a class
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
    final checks = StringBuffer(
      _throwIfFalse('Invariant', clauses, during: r'$inFlight'),
    )..writeln('_invariantVerified[this] = true;');
    final guarded = ReentrancyGuard.wrap(
      '$checks',
      when: '_invariantVerified[this] != true',
    );
    return 'extension ${invariantExtensionName(className)}$parameters '
        'on $className$arguments {\n'
        'static final Expando<bool> _invariantVerified = Expando<bool>();\n'
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
