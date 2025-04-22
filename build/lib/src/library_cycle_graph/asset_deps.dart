// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

import '../../build.dart' hide Builder;

part 'asset_deps.g.dart';

/// Dependencies of a Dart source asset.
///
/// A "dependency" is another Dart source mentioned in `import`, `export`,
/// `part` or `part of`.
///
/// Missing or not-yet-generated sources can be represented by this class: they
/// have no deps.
abstract class AssetDeps implements Built<AssetDeps, AssetDepsBuilder> {
  static Serializer<AssetDeps> get serializer => _$assetDepsSerializer;

  static final AssetDeps empty = _$AssetDeps._(deps: BuiltSet());

  BuiltSet<AssetId> get deps;

  factory AssetDeps(Iterable<AssetId> deps) =>
      _$AssetDeps._(deps: BuiltSet.of(deps));
  factory AssetDeps.build(void Function(AssetDepsBuilder) updates) =
      _$AssetDeps;
  AssetDeps._();
}
