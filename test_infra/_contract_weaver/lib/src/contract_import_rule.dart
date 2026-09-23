// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';

part 'contract_import_rule.g.dart';

/// Adds [import] to woven source that mentions any of [markers].
///
/// A clause can use a name that the library being woven does not import, most
/// often an extension member, because the clause is written by hand and is not
/// subject to the analyzer until it is woven in. Cofoja solves this with
/// `@ContractImport` on the enclosing type. Until that exists here, the caller
/// states the rules.
abstract class ContractImportRule
    implements Built<ContractImportRule, ContractImportRuleBuilder> {
  BuiltList<String> get markers;

  String get import;

  ContractImportRule._();
  factory ContractImportRule([
    void Function(ContractImportRuleBuilder) updates,
  ]) = _$ContractImportRule;

  /// Creates a [ContractImportRule] from its fields.
  factory ContractImportRule.of({
    required Iterable<String> markers,
    required String import,
  }) => _$ContractImportRule._(markers: markers.toBuiltList(), import: import);
}
