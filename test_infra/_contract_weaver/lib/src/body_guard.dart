// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';

import 'throw_clauses.dart';

part 'body_guard.g.dart';

/// The checks woven around a body so that they run however it exits.
abstract class BodyGuard implements Built<BodyGuard, BodyGuardBuilder> {
  /// Whether the body is an invariant scope: entering it checks the invariant,
  /// and so does leaving it, unless another scope on the object is open.
  bool get checksInvariant;

  BuiltList<ThrowClauses> get throwClauses;

  bool get isEmpty => !checksInvariant && throwClauses.isEmpty;

  BodyGuard._();
  factory BodyGuard([void Function(BodyGuardBuilder) updates]) = _$BodyGuard;

  /// Creates a [BodyGuard] from its fields.
  factory BodyGuard.of({
    bool checksInvariant = false,
    Iterable<ThrowClauses> throwClauses = const [],
  }) => _$BodyGuard._(
    checksInvariant: checksInvariant,
    throwClauses: throwClauses.toBuiltList(),
  );
}
