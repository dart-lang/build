// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';

part 'part_contribution.g.dart';

/// What one builder added to a shared part in one phase.
abstract class PartContribution
    implements Built<PartContribution, PartContributionBuilder> {
  /// The key of the builder that added this.
  String get builderKey;

  /// Imports to add to the part.
  BuiltList<String> get imports;

  /// Source to add to the part.
  String get contribution;

  PartContribution._();
  factory PartContribution([void Function(PartContributionBuilder) updates]) =
      _$PartContribution;

  /// Creates a [PartContribution] from its fields.
  factory PartContribution.of({
    required String builderKey,
    Iterable<String> imports = const [],
    required String contribution,
  }) => _$PartContribution._(
    builderKey: builderKey,
    imports: imports.toBuiltList(),
    contribution: contribution,
  );
}
