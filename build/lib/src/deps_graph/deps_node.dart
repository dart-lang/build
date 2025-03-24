// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';

import '../../build.dart' hide Builder;

part 'deps_node.g.dart';

abstract class DepsNode implements Built<DepsNode, DepsNodeBuilder> {
  AssetId get id;

  /// Whether this is a missing source.
  ///
  /// If so, [phase] and [deps] are `null`.
  bool get missing;

  /// If this node is generated, the phase at which it becomes readable.
  ///
  /// Or, `null` if it is not a generated source.
  int? get phase;

  /// The deps of this node.
  ///
  /// Or, `null` if it is missing.
  BuiltSet<AssetId>? get deps;

  factory DepsNode([void Function(DepsNodeBuilder)? updates]) =>
      (DepsNodeBuilder()
            ..missing = false
            ..deps
            ..update(updates))
          .build();
  DepsNode._();

  factory DepsNode.missingSource(AssetId id) =>
      _$DepsNode._(id: id, missing: true, phase: null, deps: null);

  factory DepsNode.source(AssetId id, Iterable<AssetId> deps) => _$DepsNode._(
    id: id,
    missing: false,
    phase: null,
    deps: BuiltSet.of(deps),
  );
}
