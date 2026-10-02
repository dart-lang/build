// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';

part 'throw_clauses.g.dart';

/// Clauses that must hold when a body throws [type].
abstract class ThrowClauses
    implements Built<ThrowClauses, ThrowClausesBuilder> {
  /// The source text of the exception type.
  String get type;

  BuiltList<String> get clauses;

  ThrowClauses._();
  factory ThrowClauses([void Function(ThrowClausesBuilder) updates]) =
      _$ThrowClauses;

  /// Creates a [ThrowClauses] from its fields.
  factory ThrowClauses.of({
    required String type,
    required Iterable<String> clauses,
  }) => _$ThrowClauses._(type: type, clauses: clauses.toBuiltList());
}
