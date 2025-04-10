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
  BuiltSet<AssetId> get removedAssets;

  factory AssetSet([void Function(AssetSetBuilder) updates]) = _$AssetSet;
  AssetSet._();

  AssetSet difference(Iterable<AssetId> other) {
    return rebuild((b) {
      for (final asset in other) {
        if (!b.assets.remove(asset)) {
          b.removedAssets.add(asset);
        }
      }
    });
  }

  Iterable<AssetId> get iterable {
    final seenGraphs = Set<LibraryCycleGraph>.identity();
    Iterable<AssetId> result = assets;

    for (final graph in graphs) {
      for (final graph in graph.transitiveGraphs) {
        if (seenGraphs.add(graph)) result = result.followedBy(graph.root.ids);
      }
    }

    return result.where((e) => !removedAssets.contains(e));
  }

  bool get isEmpty => iterable.isEmpty;
}
