// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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

  /// The clauses of each annotation called [name] in [metadata], in order.
  ///
  /// Each annotation holds exactly one clause.
  List<String> _clauses(NodeList<Annotation> metadata, String name) {
    final clauses = <String>[];
    for (final annotation in metadata) {
      if (annotation.name.name != name) continue;
      final args = annotation.arguments?.arguments;
      if (args == null || args.length != 1) {
        throw FormatException(
          '@$name annotation requires exactly one contract expression string; '
          'repeat the annotation for more clauses.',
        );
      }
      clauses.add(_stringValue(args.single, name));
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
      if (annotation.name.name != 'ThrowEnsures') continue;
      final args = annotation.arguments?.arguments;
      if (args == null || args.length != 2) {
        throw const FormatException(
          '@ThrowEnsures annotation requires an exception type and exactly '
          'one contract expression string; repeat the annotation for more '
          'clauses.',
        );
      }
      final type = source.substring(args.first.offset, args.first.end);
      clausesByType
          .putIfAbsent(type, () => [])
          .add(_stringValue(args.last, 'ThrowEnsures'));
    }
    return [
      for (final entry in clausesByType.entries)
        ThrowClauses.of(type: entry.key, clauses: entry.value),
    ];
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
