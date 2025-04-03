// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

import '../asset/id.dart';
import 'library_cycle_graph.dart';

part 'asset_set.g.dart';

abstract class AssetSet implements Built<AssetSet, AssetSetBuilder> {
  static Serializer<AssetSet> get serializer => _$assetSetSerializer;

  BuiltSet<AssetId> get assets;
  BuiltList<LibraryCycleGraph> get graphs;

  factory AssetSet([void Function(AssetSetBuilder) updates]) = _$AssetSet;
  AssetSet._();

  AssetSet difference(Set<AssetId> other) {
    throw UnimplementedError();
  }

  Iterable<AssetId> get iterable sync* {
    final seenAssets = assets.toSet();
    yield* assets;

    for (final graph in graphs) {
      for (final id in graph.transitiveDeps) {
        if (seenAssets.add(id)) yield id;
      }
    }
  }
}
