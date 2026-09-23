// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';

import 'invariant_hooks.dart';
import 'throw_clauses.dart';

part 'body_guard.g.dart';

/// The checks woven around a body so that they run however it exits.
abstract class BodyGuard implements Built<BodyGuard, BodyGuardBuilder> {
  InvariantHooks? get invariant;

  BuiltList<ThrowClauses> get throwClauses;

  bool get isEmpty => invariant == null && throwClauses.isEmpty;

  BodyGuard._();
  factory BodyGuard([void Function(BodyGuardBuilder) updates]) = _$BodyGuard;

  /// Creates a [BodyGuard] from its fields.
  factory BodyGuard.of({
    InvariantHooks? invariant,
    Iterable<ThrowClauses> throwClauses = const [],
  }) => _$BodyGuard._(
    invariant: invariant,
    throwClauses: throwClauses.toBuiltList(),
  );
}
