// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';

import '../asset/id.dart';
import 'deps_cycle.dart';

part 'deps_graph.g.dart';

abstract class DepsGraph implements Built<DepsGraph, DepsGraphBuilder> {
  DepsCycle get root;
  BuiltList<DepsGraph> get children;

  factory DepsGraph([void Function(DepsGraphBuilder) updates]) = _$DepsGraph;
  DepsGraph._();

  BuiltSet<AssetId> get transitiveDeps {
    return root.nodes
        .map((node) => node.id)
        .followedBy(
          children.map((graph) => graph.transitiveDeps).expand((x) => x),
        )
        .toBuiltSet();
  }
}
