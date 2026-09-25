import 'package:analyzer/dart/ast/ast.dart';

import 'reentrancy_guard.dart';

/// Clauses that must hold when a body throws [type].
class ThrowClauses {
  ThrowClauses({required this.type, required this.clauses});

  final String type;
  final List<String> clauses;
}

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

  static String preconditions(List<String> clauses) =>
      ReentrancyGuard.wrap(_throwIfFalse('Precondition', clauses));

  static String postconditions(List<String> clauses) =>
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
    List<String> clauses,
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
    List<String> clauses, {
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
