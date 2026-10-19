// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:built_collection/built_collection.dart';

import 'member_contract.dart';
import 'throw_clauses.dart';

/// Reads contract clauses from annotations.
///
/// Annotations are matched by name, so any annotation with a matching name is
/// read whatever library declares it.
class ClauseReader {
  ClauseReader(this.source);

  /// The names of the contract annotations.
  static const annotationNames = {
    'Requires',
    'Ensures',
    'ThrowEnsures',
    'Invariant',
    'ContractImport',
  };

  /// The source that the annotations were parsed from.
  final String source;

  /// The clauses on a function, method or constructor.
  MemberContract read(NodeList<Annotation> metadata) => MemberContract(
    (b) => b
      ..preconditions.replace(_clauses(metadata, 'Requires'))
      ..postconditions.replace(_clauses(metadata, 'Ensures'))
      ..throwClauses.replace(throwClauses(metadata)),
  );

  /// The `@Invariant` clauses on a class.
  BuiltList<String> invariants(NodeList<Annotation> metadata) =>
      _clauses(metadata, 'Invariant').toBuiltList();

  /// The URIs of the `@ContractImport` annotations in [metadata]: libraries
  /// that clauses use but the annotated library does not import.
  List<String> contractImports(NodeList<Annotation> metadata) =>
      _clauses(metadata, 'ContractImport');

  /// The clauses of each annotation called [name] in [metadata], in order.
  ///
  /// Each annotation holds exactly one clause.
  List<String> _clauses(NodeList<Annotation> metadata, String name) {
    final clauses = <String>[];
    for (final annotation in metadata) {
      if (!_isNamed(annotation, name)) continue;
      final args = annotation.arguments?.arguments;
      if (args == null || args.length != 1) {
        throw FormatException(
          '@$name annotation requires exactly one contract expression string; '
          'repeat the annotation for more clauses.',
        );
      }
      final value = _stringValue(args.single, name);
      if (name != 'ContractImport') _checkExpression(value, name);
      clauses.add(value);
    }
    return clauses;
  }

  /// The clauses of the `@ThrowEnsures` annotations in [metadata], grouped by
  /// exception type.
  ///
  /// Each annotation holds an exception type and exactly one clause. Groups are
  /// ordered by the first annotation for each type; clauses within a group keep
  /// their annotation order.
  List<ThrowClauses> throwClauses(NodeList<Annotation> metadata) {
    final clausesByType = <String, List<String>>{};
    for (final annotation in metadata) {
      if (!_isNamed(annotation, 'ThrowEnsures')) continue;
      final args = annotation.arguments?.arguments;
      if (args == null || args.length != 2) {
        throw const FormatException(
          '@ThrowEnsures annotation requires an exception type and exactly '
          'one contract expression string; repeat the annotation for more '
          'clauses.',
        );
      }
      final type = source.substring(args.first.offset, args.first.end);
      final value = _stringValue(args.last, 'ThrowEnsures');
      _checkExpression(value, 'ThrowEnsures');
      clausesByType.putIfAbsent(type, () => []).add(value);
    }
    return [
      for (final entry in clausesByType.entries)
        ThrowClauses.of(type: entry.key, clauses: entry.value),
    ];
  }

  /// Whether [annotation] is called [name].
  ///
  /// Throws if it is called [name] through an import prefix: woven code
  /// refers to the injected runtime support without a prefix.
  static bool _isNamed(Annotation annotation, String name) {
    final identifier = annotation.name;
    if (identifier is PrefixedIdentifier) {
      if (identifier.identifier.name != name) return false;
      throw FormatException(
        '@${identifier.name} is not supported; import the library that '
        'declares @$name without a prefix.',
      );
    }
    return identifier.name == name;
  }

  /// Throws if [clause], from an annotation called [name], is not a single
  /// Dart expression.
  ///
  /// The clause is the value of a string literal, so escapes in it have
  /// already been processed: `'\\n'` in the annotation is a backslash and an
  /// `n` in the clause, but `'\n'` is a line break.
  static void _checkExpression(String clause, String name) {
    final parsed = parseString(
      content: 'final _ = ($clause);',
      throwIfDiagnostics: false,
    );
    if (clause.trim().isEmpty || parsed.errors.isNotEmpty) {
      throw FormatException('@$name clause is not a Dart expression: $clause');
    }
  }

  /// The value of [arg], which must be a string literal with no interpolation.
  String _stringValue(Argument arg, String name) {
    if (arg is SimpleStringLiteral) return arg.value;
    if (arg is StringLiteral) {
      final value = arg.stringValue;
      if (value != null) return value;
      throw FormatException(
        '@$name contract expression must be a non-empty string literal.',
      );
    }
    throw FormatException(
      '@$name contract expression must be a string literal, '
      'got: ${source.substring(arg.offset, arg.end)}',
    );
  }
}
