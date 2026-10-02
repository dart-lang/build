// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';

import 'throw_clauses.dart';

part 'member_contract.g.dart';

/// The contract annotations on one function, method or constructor.
abstract class MemberContract
    implements Built<MemberContract, MemberContractBuilder> {
  /// The `@Requires` clauses, in annotation order.
  BuiltList<String> get preconditions;

  /// The `@Ensures` clauses, in annotation order.
  BuiltList<String> get postconditions;

  /// The `@ThrowEnsures` clauses, grouped by exception type.
  BuiltList<ThrowClauses> get throwClauses;

  /// Whether there are no clauses at all.
  bool get isEmpty =>
      preconditions.isEmpty && postconditions.isEmpty && throwClauses.isEmpty;

  MemberContract._();
  factory MemberContract([void Function(MemberContractBuilder) updates]) =
      _$MemberContract;
}
